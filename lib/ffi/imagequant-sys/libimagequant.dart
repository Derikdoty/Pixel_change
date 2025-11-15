import 'dart:ffi' as ffi;
import 'dart:io';

typedef liq_version_native = ffi.Int32 Function();
typedef LiqVersion = int Function();

class LibImageQuant {
  static final ffi.DynamicLibrary _lib = () {
    if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('libimagequant_sys.a');
    } else if (Platform.isMacOS) {
      return ffi.DynamicLibrary.process();
    } else if (Platform.isLinux) {
      return ffi.DynamicLibrary.open('libimagequant_sys.a');
    } else {
      throw UnsupportedError('This platform is not supported.');
    }
  }();

  static final LiqVersion liqVersion = _lib
      .lookup<ffi.NativeFunction<liq_version_native>>('liq_version')
      .asFunction();
}
