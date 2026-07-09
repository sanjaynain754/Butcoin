// BUT Network - Rust FFI Bridge
// Connects Flutter wallet to but-crypto Rust library

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// C function signatures
typedef GenerateKeypairNative = Pointer<Utf8> Function();
typedef GenerateKeypairDart = Pointer<Utf8> Function();

typedef DeriveFromSeedNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef DeriveFromSeedDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef SignMessageNative = Pointer<Utf8> Function(Pointer<Utf8>, Uint8);
typedef SignMessageDart = Pointer<Utf8> Function(Pointer<Utf8>, int);

typedef FreeStringNative = Void Function(Pointer<Utf8>);
typedef FreeStringDart = void Function(Pointer<Utf8>);

typedef GetVersionNative = Pointer<Utf8> Function();
typedef GetVersionDart = Pointer<Utf8> Function();

class RustBridge {
  static DynamicLibrary? _lib;
  static bool _initialized = false;

  // FFI function pointers
  static GenerateKeypairDart? _generate512;
  static GenerateKeypairDart? _generate1024;
  static DeriveFromSeedDart? _derive512;
  static SignMessageDart? _signMessage;
  static FreeStringDart? _freeString;
  static GetVersionDart? _getVersion;

  /// Initialize Rust FFI bridge
  static bool initialize() {
    if (_initialized) return true;

    try {
      // Load the Rust library based on platform
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libbut_crypto.so');
      } else if (Platform.isIOS) {
        _lib = DynamicLibrary.open('libbut_crypto.dylib');
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('libbut_crypto.so');
      } else if (Platform.isMacOS) {
        _lib = DynamicLibrary.open('libbut_crypto.dylib');
      } else if (Platform.isWindows) {
        _lib = DynamicLibrary.open('but_crypto.dll');
      } else {
        return false;
      }

      // Load function pointers
      _generate512 = _lib!
          .lookupFunction<GenerateKeypairNative, GenerateKeypairDart>(
              'generate_512_keypair');

      _generate1024 = _lib!
          .lookupFunction<GenerateKeypairNative, GenerateKeypairDart>(
              'generate_1024_keypair');

      _derive512 = _lib!
          .lookupFunction<DeriveFromSeedNative, DeriveFromSeedDart>(
              'derive_512_from_seed');

      _signMessage = _lib!
          .lookupFunction<SignMessageNative, SignMessageDart>(
              'sign_message_512');

      _freeString = _lib!
          .lookupFunction<FreeStringNative, FreeStringDart>(
              'free_rust_string');

      _getVersion = _lib!
          .lookupFunction<GetVersionNative, GetVersionDart>(
              'get_but_crypto_version');

      _initialized = true;
      return true;
    } catch (e) {
      // Silent fail - app will use Dart fallback
      _initialized = false;
      return false;
    }
  }

  /// Generate 512-bit keypair via Rust
  static String? generate512Keypair() {
    if (!_initialized || _generate512 == null) return null;

    final resultPtr = _generate512!();
    final result = resultPtr.toDartString();
    _freeString!(resultPtr);
    return result;
  }

  /// Generate 1024-bit vault keypair via Rust
  static String? generate1024Keypair() {
    if (!_initialized || _generate1024 == null) return null;

    final resultPtr = _generate1024!();
    final result = resultPtr.toDartString();
    _freeString!(resultPtr);
    return result;
  }

  /// Derive 512-bit keys from seed via Rust
  static String? derive512FromSeed(String seedHex) {
    if (!_initialized || _derive512 == null) return null;

    final seedPtr = seedHex.toNativeUtf8();
    final resultPtr = _derive512!(seedPtr);
    final result = resultPtr.toDartString();
    
    _freeString!(resultPtr);
    calloc.free(seedPtr);
    
    return result;
  }

  /// Sign message via Rust hybrid signature
  static String? signMessage(String message, int level) {
    if (!_initialized || _signMessage == null) return null;

    final msgPtr = message.toNativeUtf8();
    final resultPtr = _signMessage!(msgPtr, level);
    final result = resultPtr.toDartString();
    
    _freeString!(resultPtr);
    calloc.free(msgPtr);
    
    return result;
  }

  /// Get Rust library version
  static String? getVersion() {
    if (!_initialized || _getVersion == null) return null;

    final resultPtr = _getVersion!();
    final result = resultPtr.toDartString();
    _freeString!(resultPtr);
    return result;
  }

  /// Check if Rust FFI is available
  static bool get isAvailable => _initialized;
}
