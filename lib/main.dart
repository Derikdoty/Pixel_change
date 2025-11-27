import 'dart:io';
import 'dart:typed_data';  
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'imagequant_ffi.dart';
import 'pixel_painter.dart';  

final List<Color> nesPalette = [
  const Color(0xFF1A1A1A),
  const Color(0xFF404040),
  const Color(0xFF808080),
  const Color(0xFFC0C0C0),
  const Color(0xFFFFFFFF),
  const Color(0xFF8B0000),
  const Color(0xFFFF0000),
  const Color(0xFFFFA500),
  const Color(0xFFFFD700),
  const Color(0xFFFFFF00),
  const Color(0xFFE5E500),
  const Color(0xFFFFF380),
  const Color(0xFF006400),
  const Color(0xFF008000),
  const Color(0xFF00FF00),
  const Color(0xFF98FB98),
  const Color(0xFF000080),
  const Color(0xFF0000FF),
  const Color(0xFF87CEFA),
  const Color(0xFFADD8E6),
  const Color(0xFF800080),
  const Color(0xFFBA55D3),
  const Color(0xFFDDA0DD),
  const Color(0xFF8B4513),
  const Color(0xFFA0522D),
  const Color(0xFFDEB887),
  const Color(0xFF008080),
  const Color(0xFF00FFFF),
  const Color(0xFF40E0D0),
  const Color(0xFF2F4F4F),
  const Color(0xFF228B22),
  const Color(0xFF556B2F),
  const Color(0xFF2E8B57),
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Editor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ImagePickerPage(),
    );
  }
}

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({super.key});
  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  File? _image;
  List<List<Color>>? _pixelGrid;
  double _ditheringIntensity = 5.0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    print("=== PICKIMAGE CALLED ===");
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      print("✓ Image picked: ${image.path}");
      final bytes = await image.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage != null) {
        print("✓ Image decoded successfully");
        final stopwatch = Stopwatch()..start();
        final resized = img.copyResize(originalImage, width: 128);
        print("✓ Resized to ${resized.width}x${resized.height} in ${stopwatch.elapsedMilliseconds}ms");
        
        stopwatch.reset();
        
        final rgbaPixels = Uint8List(resized.width * resized.height * 4);
        int offset = 0;
        for (int y = 0; y < resized.height; y++) {
          for (int x = 0; x < resized.width; x++) {
            final pixel = resized.getPixel(x, y);
            rgbaPixels[offset++] = pixel.r.toInt();
            rgbaPixels[offset++] = pixel.g.toInt();
            rgbaPixels[offset++] = pixel.b.toInt();
            rgbaPixels[offset++] = pixel.a.toInt();
          }
        }
        
        print("✓ RGBA conversion took: ${stopwatch.elapsedMilliseconds}ms");
        stopwatch.reset();

        print(">>> CALLING LIBIMAGEQUANT <<<");
        final quantizedColors = ImageQuantFFI.quantizeImage(
          rgbaPixels: rgbaPixels,
          width: resized.width,
          height: resized.height,
          palette: nesPalette,
          maxColors: nesPalette.length,
          ditherLevel: _ditheringIntensity / 10.0,
        );
        
        print("✓ Quantization took: ${stopwatch.elapsedMilliseconds}ms");

        if (quantizedColors != null) {
          print("✓✓✓ SUCCESS: Using libimagequant result with ${quantizedColors.length} colors");
          
          List<List<Color>> grid = [];
          for (int y = 0; y < resized.height; y++) {
            List<Color> row = [];
            for (int x = 0; x < resized.width; x++) {
              row.add(quantizedColors[y * resized.width + x]);
            }
            grid.add(row);
          }

          setState(() {
            _image = File(image.path);
            _pixelGrid = grid;
          });
          
          print("=== QUANTIZATION COMPLETE ===");
        } else {
          print("✗✗✗ FAILED: libimagequant returned null");
        }
      } else {
        print("✗ Failed to decode image");
      }
    } else {
      print("✗ No image picked");
    }
  }

  void _changePixelColor(int x, int y) async {
    Color currentColor = _pixelGrid![y][x];
    Color? newColor = await showDialog<Color>(
      context: context,
      builder: (context) {
        Color tempColor = currentColor;
        return AlertDialog(
          title: const Text('Pick a new color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: currentColor,
              onColorChanged: (color) {
                tempColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempColor),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (newColor != null) {
      setState(() {
        _pixelGrid![y][x] = newColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pixel Editor')),
      body: Column(
        children: [
          Expanded(
            child: _pixelGrid != null
                ? InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
                    minScale: 0.1,
                    maxScale: 10.0,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: FittedBox(
                      fit: BoxFit.contain,
                        child: CustomPaint(
                          size: Size(
                            _pixelGrid![0].length * 10.0,
                            _pixelGrid!.length * 10.0,
                      ),
                      painter: PixelPainter(_pixelGrid!, pixelSize: 10),
                    ),
                    )
                  )
                : const Center(child: Text('No image selected')),
          ),
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Pick and Pixelate Image'),
          ),
          ElevatedButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: const Text("Close App"),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Text('Dithering Intensity: ${_ditheringIntensity.toStringAsFixed(1)}'),
              Slider(
                value: _ditheringIntensity,
                min: 0,
                max: 10,
                divisions: 100,
                label: _ditheringIntensity.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _ditheringIntensity = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}