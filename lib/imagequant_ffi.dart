import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'src/bindings.dart';

class ImageQuantFFI {
  static LibImageQuantBindings? _bindings;
  
  static LibImageQuantBindings _getBindings() {
    if (_bindings != null) return _bindings!;
    
    try {
      print("Loading libimagequant library...");
      final lib = _loadLibrary();
      _bindings = LibImageQuantBindings(lib);
      
      final version = _bindings!.liq_version();
      print("Successfully loaded libimagequant version: $version");
      
      return _bindings!;
    } catch (e) {
      print("ERROR loading library: $e");
      rethrow;
    }
  }

  static ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('libimage_quant_ffi.so');
    } else if (Platform.isIOS) {
      return ffi.DynamicLibrary.process();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  static List<Color>? quantizeImage({
  required Uint8List rgbaPixels,
  required int width,
  required int height,
  required List<Color> palette,
  int maxColors = 256,
  double ditherLevel = 1.0,
}) {
  try {
    final bindings = _getBindings();
    print("Starting quantization for ${width}x${height} image");
    
    final attr = bindings.liq_attr_create();
    if (attr == ffi.nullptr) {
      print('Failed to create liq_attr');
      return null;
    }

    bindings.liq_set_max_colors(attr, maxColors.clamp(2, 256));
    
    final pixelPointer = malloc<ffi.Uint8>(rgbaPixels.length);
    final pixelList = pixelPointer.asTypedList(rgbaPixels.length);
    pixelList.setAll(0, rgbaPixels);

    final image = bindings.liq_image_create_rgba(
      attr,
      pixelPointer.cast<ffi.Void>(),
      width,
      height,
      0.0,
    );

    if (image == ffi.nullptr) {
      print('Failed to create liq_image');
      malloc.free(pixelPointer);
      bindings.liq_attr_destroy(attr);
      return null;
    }

    // Fix: Use the correct type from bindings
    final resultPtr = calloc<ffi.Pointer<ffi.NativeType>>();
    final quantizeResult = bindings.liq_image_quantize(
      image,
      attr,
      resultPtr.cast(), // Just cast without specifying the full type
    );

    if (quantizeResult != 0) {
      print('Quantization failed with error: $quantizeResult');
      calloc.free(resultPtr);
      bindings.liq_image_destroy(image);
      malloc.free(pixelPointer);
      bindings.liq_attr_destroy(attr);
      return null;
    }

    final result = resultPtr.value;
    bindings.liq_set_dithering_level(result.cast(), ditherLevel);

    final palettePtr = bindings.liq_get_palette(result.cast());
    final paletteCount = palettePtr.ref.count;

    print('Generated palette with $paletteCount colors');

    final remappedBuffer = malloc<ffi.Uint8>(width * height);
    final remapResult = bindings.liq_write_remapped_image(
      result.cast(),
      image,
      remappedBuffer.cast<ffi.Void>(),
      width * height,
    );

    if (remapResult != 0) {
      print('Remapping failed with error: $remapResult');
      malloc.free(remappedBuffer);
      calloc.free(resultPtr);
      bindings.liq_result_destroy(result.cast());
      bindings.liq_image_destroy(image);
      malloc.free(pixelPointer);
      bindings.liq_attr_destroy(attr);
      return null;
    }

    final remappedList = remappedBuffer.asTypedList(width * height);
    final outputColors = <Color>[];

    for (int i = 0; i < width * height; i++) {
      final paletteIndex = remappedList[i];
      if (paletteIndex < paletteCount) {
        final entry = palettePtr.ref.entries[paletteIndex];
        outputColors.add(Color.fromARGB(
          entry.a,
          entry.r,
          entry.g,
          entry.b,
        ));
      } else {
        outputColors.add(Colors.black);
      }
    }

    malloc.free(remappedBuffer);
    calloc.free(resultPtr);
    bindings.liq_result_destroy(result.cast());
    bindings.liq_image_destroy(image);
    malloc.free(pixelPointer);
    bindings.liq_attr_destroy(attr);

    return outputColors;
  } catch (e) {
    print('Error in quantizeImage: $e');
    return null;
  }
}
}