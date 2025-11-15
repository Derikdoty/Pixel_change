import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // Alias the image package
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';

// Define the NES Palette (EXAMPLE - you'll want a full 64-color NES palette here)
// Current palette is incomplete for accurate NES-style results.
final List<Color> nesPalette = [
  // Grayscale
  const Color(0xFF1A1A1A), // Dark Grey
  const Color(0xFF404040), // Mid Dark Grey (Uncommented your original entry)
  const Color(0xFF808080), // Mid Grey (Uncommented your original entry)
  const Color(0xFFC0C0C0), // Light Grey (Uncommented your original entry)
  const Color(0xFFFFFFFF), // White

  // Reds and Oranges
  const Color(0xFF8B0000), // Dark Red
  const Color(0xFFFF0000), // Red
  const Color(0xFFFFA500), // Orange
  const Color(0xFFFFD700), // Gold

  // Yellows
  const Color(0xFFFFFF00), // Yellow
  const Color(0xFFE5E500), // Darker Yellow
  const Color(0xFFFFF380), // Light Yellow

  // Greens
  const Color(0xFF006400), // Dark Green
  const Color(0xFF008000), // Green
  const Color(0xFF00FF00), // Bright Green
  const Color(0xFF98FB98), // Pale Green

  // Blues
  const Color(0xFF000080), // Navy Blue
  const Color(0xFF0000FF), // Blue
  const Color(0xFF87CEFA), // Light Sky Blue
  const Color(0xFFADD8E6), // Light Blue

  // Purples
  const Color(0xFF800080), // Purple
  const Color(0xFFBA55D3), // Medium Orchid
  const Color(0xFFDDA0DD), // Plum

  // Browns
  const Color(0xFF8B4513), // Saddle Brown
  const Color(0xFFA0522D), // Sienna
  const Color(0xFFDEB887), // Burly Wood (Uncommented your original entry)

  // Teals / Cyan
  const Color(0xFF008080), // Teal
  const Color(0xFF00FFFF), // Aqua/Cyan
  const Color(0xFF40E0D0), // Turquoise

  const Color(0xFF2F4F4F), // Dark Slate Gray (actually a greenish gray)
  const Color(0xFF228B22), // Forest Green
  const Color(0xFF556B2F), // Dark Olive Green
  const Color(0xFF2E8B57), // Sea Green
];


// **MISSING GLOBAL DEFINITION ADDED HERE**
// Bayer Matrix (matching your 4x4 usage)
const List<List<int>> bayerMatrix4x4 = [
  [ 0, 8, 2, 10 ],
  [ 12, 4, 14, 6 ],
  [ 3, 11, 1, 9 ],
  [ 15, 7, 13, 5 ],
];

// **MISSING GLOBAL DEFINITIONS FOR LAB CONVERSION AND COLOR FINDING ADDED HERE**
// Note: For accurate CIELAB color conversion, consider using a dedicated package
// like 'colorsys' or 'color'. These are simplified placeholders to make the code compile.

/// Converts an RGB Color to a List of [L, A, B] components (simplified pseudo-LAB).
/// For accurate CIELAB, use a robust color conversion library.
List<double> colorToLab(Color color) {
  // Normalize RGB to 0-1 range
  double r = color.red / 255.0;
  double g = color.green / 255.0;
  double b = color.blue / 255.0;

  // Simple pseudo-LAB conversion - this is NOT true CIELAB
  // It provides a rough separation of lightness (L) and color components (A, B)
  double l = (r * 0.2126 + g * 0.7152 + b * 0.0722) * 100.0; // Perceived Luminance
  double a = (r - g) * 100.0; // Red-Green component
  double bComp = (g - b) * 100.0; // Green-Blue component (renamed to avoid conflict)

  return [l, a, bComp];
}

/// Converts a List of [L, A, B] components back to an RGB Color (simplified pseudo-LAB).
/// For accurate CIELAB, use a robust color conversion library.
Color labToColor(List<double> lab) {
  double l = lab[0];
  double a = lab[1];
  double bComp = lab[2]; // Renamed to avoid conflict

  // Simple reverse conversion - this is highly inaccurate for true CIELAB
  // and will not perfectly recreate original RGB from the simplified LAB.
  double r = (l / 100.0 + a / 100.0).clamp(0.0, 1.0);
  double g = (l / 100.0 - a / 100.0 + bComp / 100.0).clamp(0.0, 1.0);
  double b = (l / 100.0 - bComp / 100.0).clamp(0.0, 1.0);

  return Color.fromARGB(
    255, // Alpha
    (r * 255).round().clamp(0, 255),
    (g * 255).round().clamp(0, 255),
    (b * 255).round().clamp(0, 255),
  );
}

/// Calculates the squared Euclidean distance between two LAB color points.
double labDistance(List<double> lab1, List<double> lab2) {
  final dl = lab1[0] - lab2[0];
  final da = lab1[1] - lab2[1];
  final db = lab1[2] - lab2[2];
  return dl * dl + da * da + db * db; // Squared Euclidean distance
}

/// Finds the closest color in `nesPalette` to the `targetColor` using LAB distance.
Color findClosestNESColorLab(Color targetColor) {
  final targetLab = colorToLab(targetColor);
  double minDistance = double.infinity;
  Color closestColor = targetColor; // Default to target if palette is empty or no match

  if (nesPalette.isEmpty) {
    return targetColor; // Or throw an error, depending on desired behavior
  }

  for (final nesColor in nesPalette) {
    final nesLab = colorToLab(nesColor);
    final distance = labDistance(targetLab, nesLab);
    if (distance < minDistance) {
      minDistance = distance;
      closestColor = nesColor;
    }
  }
  return closestColor;
}


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

  // **MISSING INSTANCE VARIABLES ADDED HERE**
  double _weightL = 1.0; // Initial value, adjust as needed
  double _weightA = 1.0; // Initial value
  double _weightB = 1.0; // Initial value

  final Map<int, Color> _colorCache = {};

  @override
  void initState() {
    super.initState();
  }

  // Helper function to find the nearest lighter color in the palette
  Color _findNearestLighterColor(Color color) {
    final labColor = colorToLab(color);
    double minDistance = double.infinity;
    Color nearestLighter = color; // Default to original if no lighter found

    for (final nesColor in nesPalette) {
      final nesLab = colorToLab(nesColor);
      if (nesLab[0] > labColor[0]) { // Check if it's lighter (L component is lightness)
        final distance = labDistance(labColor, nesLab);
        if (distance < minDistance) {
          minDistance = distance;
          nearestLighter = nesColor;
        }
      }
    }
    return nearestLighter;
  }

  // Helper function to find the nearest darker color in the palette
  Color _findNearestDarkerColor(Color color) {
    final labColor = colorToLab(color);
    double minDistance = double.infinity;
    Color nearestDarker = color; // Default to original if no darker found

    for (final nesColor in nesPalette) {
      final nesLab = colorToLab(nesColor);
      if (nesLab[0] < labColor[0]) { // Check if it's darker (L component is lightness)
        final distance = labDistance(labColor, nesLab);
        if (distance < minDistance) {
          minDistance = distance;
          nearestDarker = nesColor;
        }
      }
    }
    return nearestDarker;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      print("Image picked: ${image.path}");
      final bytes = await image.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage != null) {
        print("Image decoded successfully");
        final resized = img.copyResize(originalImage, width: 128);
        List<List<Color>> grid = [];

        for (int y = 0; y < resized.height; y++) {
          List<Color> row = [];

          for (int x = 0; x < resized.width; x++) {
            final pixel = resized.getPixel(x, y);

            final originalColor = Color.fromARGB(
              pixel.a.toInt(),
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
            );

            // Convert to Lab
            final lab = colorToLab(originalColor);

            // Apply Bayer dithering to L channel
            final bayerX = x % 4;
            final bayerY = y % 4;
            final bayerValue = bayerMatrix4x4[bayerY][bayerX];
            final threshold = (bayerValue / 16.0 - 0.5) * _ditheringIntensity;

            final adjustedLab = [
              (lab[0] + threshold).clamp(0, 100).toDouble(),
              lab[1],
              lab[2],
            ];

            final adjustedColor = labToColor(adjustedLab);

            // Use cache to find closest NES color
            final cacheKey = adjustedColor.value; // Use int as key for consistent hashing
            final matchedColor = _colorCache.putIfAbsent(
              cacheKey,
              () => findClosestNESColorLab(adjustedColor),
            );

            row.add(matchedColor);

            // Debug print every 10th row
            if (x == 0 && y % 10 == 0) {
              print("Row $y starts with color: ${matchedColor.value.toRadixString(16)}");
            }
          }

          grid.add(row);
        }
        setState(() {
          _image = File(image.path);
          _pixelGrid = grid;
        });
      }else {
        print("Failed to decode image.");
      }
    }else {
      print("No image picked.");
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
                    minScale: 1.0,
                    maxScale: 10.0,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(), // prevent scroll clashing with pan
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _pixelGrid![0].length,
                      ),
                      itemCount: _pixelGrid!.length * _pixelGrid![0].length,
                      itemBuilder: (context, index) {
                        int x = index % _pixelGrid![0].length;
                        int y = index ~/ _pixelGrid![0].length;
                        return GestureDetector(
                          onTap: () => _changePixelColor(x, y),
                          child: Container(
                            color: _pixelGrid![y][x],
                            width: 10,
                            height: 10,
                          ),
                        );
                      },
                    ),
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

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Weight L (Lightness)"),
              Slider(
                value: _weightL,
                min: 0.0,
                max: 3.0,
                divisions: 30,
                label: _weightL.toStringAsFixed(2),
                onChanged: (value) {
                  setState(() {
                    _weightL = value;
                  });
                },
              ),
              const Text("Weight A (Green–Red)"),
              Slider(
                value: _weightA,
                min: 0.0,
                max: 3.0,
                divisions: 30,
                label: _weightA.toStringAsFixed(2),
                onChanged: (value) {
                  setState(() {
                    _weightA = value;
                  });
                },
              ),
              const Text("Weight B (Blue–Yellow)"),
              Slider(
                value: _weightB,
                min: 0.0,
                max: 3.0,
                divisions: 30,
                label: _weightB.toStringAsFixed(2),
                onChanged: (value) {
                  setState(() {
                    _weightB = value;
                  });
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}