#include <stdio.h> // Standard I/O for printing to console (optional)
#include <string.h> // For string manipulation (optional)
#include <stdbool.h> // For boolean types (optional)
#include <android/log.h> // For Android logging (useful for debugging native code)
#include <stdlib.h> // For memory allocation
// Include libimagequant header
#include "libimagequant.h"

// Define a tag for logging (for Android's logcat)
#define TAG "FlutterImageQuantFFI"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)

// This is a simple test function that Dart will call.
// It takes a string and prints it to the Android logcat.
// Replace `const char* input` with the actual data you want to pass.
void process_image_with_libimagequant(const char* input_string) {
    LOGD("C: Received string from Dart: %s", input_string);
    // Here you would integrate libimagequant functions:
    // liq_attr *attr = liq_attr_create();
    // liq_attr_set_max_colors(attr, 256); // Example: set max colors
    // ... (rest of your libimagequant logic)
}

// You can add more functions here that your Dart code will call.
// For example, a function to process image bytes and return results.