import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'package:win32_registry/win32_registry.dart';
import 'common.dart';

const _cryptProtectUiForbidden = 0x1;

// POSIX chmod(2) from libc (macOS/Linux), used to pin the persisted
// helper auth key file to owner-only permissions (AM-02/T278).
typedef _ChmodNative = Int32 Function(Pointer<Utf8> path, Uint32 mode);
typedef _ChmodFn = int Function(Pointer<Utf8> path, int mode);

class HelperAuthManager {
  static String? _authKey;
  static Future<bool>? _ensuringAuthKey;

  static String? getAuthKey() => _authKey;

  static Future<bool> ensureAuthKey() async {
    if (_authKey != null) {
      return false;
    }
    return _ensuringAuthKey ??= _loadAuthKey().whenComplete(
      () => _ensuringAuthKey = null,
    );
  }

  static Future<bool> _loadAuthKey() async {
    if (Platform.isWindows) {
      commonPrint.log(
        '[HelperAuth] Trying to sync auth key from registry for service: $appHelperService',
      );
      RegistryKey? key;
      try {
        final keyPath =
            'SYSTEM\\CurrentControlSet\\Services\\$appHelperService';
        key = LOCAL_MACHINE.open(
          keyPath,
          config: const RegistryOpenConfig(access: RegistryAccess.read),
        );
        final list = key.getValue('Environment');
        if (list case MultiStringValue(:final value)) {
          for (final item in value) {
            if (item.startsWith('HELPER_AUTH_KEY=')) {
              final val = item.substring('HELPER_AUTH_KEY='.length);
              if (_isValidHexKey(val)) {
                _authKey = val;
                final file = File(await appPath.helperAuthKeyPath);
                await _persistAuthKey(file, _authKey!);
                commonPrint.log(
                  '[HelperAuth] Successfully synced auth key from registry.',
                );
                return false;
              }
            }
          }
        }
      } catch (e) {
        commonPrint.warn('[HelperAuth] Failed to read registry: $e');
      } finally {
        key?.close();
      }
    }

    final file = File(await appPath.helperAuthKeyPath);
    final existingKey = await _readPersistedAuthKey(file);
    if (existingKey != null) {
      _authKey = existingKey;
      commonPrint.log('[HelperAuth] Loaded auth key from file.');
      return false;
    }

    _authKey = _generateRandomKey();
    await _persistAuthKey(file, _authKey!);
    commonPrint.log('[HelperAuth] Generated new random auth key.');
    return true;
  }

  static Map<String, String> generateAuthHeaders(String body) {
    final authKey = _authKey;
    if (authKey == null) {
      return {};
    }
    return generateAuthHeadersWithKey(body, authKey);
  }

  static Map<String, String> generateAuthHeadersWithKey(
    String body,
    String authKey,
  ) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final message = '$timestamp:$body';

    final keyBytes = _hexToBytes(authKey);
    final messageBytes = utf8.encode(message);
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(messageBytes);
    final signature = digest.toString();

    return {'X-Timestamp': timestamp.toString(), 'X-Signature': signature};
  }

  static Future<void> clearAuthKey() async {
    _authKey = null;
    final file = File(await appPath.helperAuthKeyPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String _generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<String?> _readPersistedAuthKey(File file) async {
    if (!await file.exists()) {
      return null;
    }

    // AM-02/T278: key files persisted before the 0600 hardening may carry
    // umask-default permissions (typically 0644, readable by other local
    // users). Tighten them on read; best effort, never blocks the read.
    if (!Platform.isWindows) {
      await _tightenKeyFilePermissions(file);
    }

    try {
      final encoded = await file.readAsString();
      if (encoded.isEmpty) {
        return null;
      }
      final encrypted = base64Decode(encoded);
      final decrypted = Platform.isWindows
          ? _unprotectForCurrentUser(Uint8List.fromList(encrypted))
          : Uint8List.fromList(encrypted);
      final key = utf8.decode(decrypted);
      if (!_isValidHexKey(key)) {
        return null;
      }
      return key;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _persistAuthKey(File file, String key) async {
    final raw = Uint8List.fromList(utf8.encode(key));
    final encrypted = Platform.isWindows ? _protectForCurrentUser(raw) : raw;
    final parentExisted = await file.parent.exists();
    await file.parent.create(recursive: true);
    await file.writeAsString(base64Encode(encrypted), flush: true);
    if (!Platform.isWindows) {
      // AM-02/T278: on POSIX platforms the payload above is only base64,
      // so the file mode is the access control. A parent directory created
      // by the app for the key gets 0700; the key file itself gets 0600.
      if (!parentExisted) {
        await _setPosixMode(file.parent.path, _modeOwnerOnlyDir);
      }
      await _setPosixMode(file.path, _modeOwnerOnlyFile);
    }
  }

  // POSIX modes: 0700 for a directory, 0600 for a file.
  static const _modeOwnerOnlyDir = 0x1C0;
  static const _modeOwnerOnlyFile = 0x180;

  static Future<void> _tightenKeyFilePermissions(File file) async {
    try {
      final stat = await file.stat();
      // Any group/other permission bit means looser than 0600.
      if ((stat.mode & 0x3F) != 0) {
        await _setPosixMode(file.path, _modeOwnerOnlyFile);
      }
    } catch (_) {
      // Best effort only; a failed stat/chmod must not break key loading.
    }
  }

  static Future<void> _setPosixMode(String path, int mode) async {
    final chmod = _chmodFn;
    if (chmod == null) {
      return;
    }
    final pathPtr = path.toNativeUtf8();
    try {
      chmod(pathPtr, mode);
    } catch (_) {
      // Best effort only (e.g. filesystem without POSIX modes).
    } finally {
      calloc.free(pathPtr);
    }
  }

  static _ChmodFn? _chmodFnCache;
  static bool _chmodFnResolved = false;

  static _ChmodFn? get _chmodFn {
    if (_chmodFnResolved) {
      return _chmodFnCache;
    }
    _chmodFnResolved = true;
    try {
      final lib = Platform.isMacOS
          ? DynamicLibrary.open('libSystem.dylib')
          : DynamicLibrary.open('libc.so.6');
      _chmodFnCache = lib.lookupFunction<_ChmodNative, _ChmodFn>('chmod');
    } catch (_) {
      _chmodFnCache = null;
    }
    return _chmodFnCache;
  }

  static bool _isValidHexKey(String value) {
    return RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
  }

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  static Uint8List _protectForCurrentUser(Uint8List input) {
    final dataIn = calloc<CRYPT_INTEGER_BLOB>();
    final dataOut = calloc<CRYPT_INTEGER_BLOB>();
    final inputBuffer = calloc<Uint8>(input.length);

    try {
      inputBuffer.asTypedList(input.length).setAll(0, input);
      dataIn.ref.cbData = input.length;
      dataIn.ref.pbData = inputBuffer;

      final result = CryptProtectData(
        dataIn,
        null,
        null,
        null,
        _cryptProtectUiForbidden,
        dataOut,
      );
      if (!result.value) {
        throw WindowsException(result.error.toHRESULT());
      }

      return Uint8List.fromList(
        dataOut.ref.pbData.asTypedList(dataOut.ref.cbData),
      );
    } finally {
      if (dataOut.ref.pbData != nullptr) {
        LocalFree(HLOCAL(dataOut.ref.pbData));
      }
      calloc.free(inputBuffer);
      calloc.free(dataIn);
      calloc.free(dataOut);
    }
  }

  static Uint8List _unprotectForCurrentUser(Uint8List input) {
    final dataIn = calloc<CRYPT_INTEGER_BLOB>();
    final dataOut = calloc<CRYPT_INTEGER_BLOB>();
    final inputBuffer = calloc<Uint8>(input.length);

    try {
      inputBuffer.asTypedList(input.length).setAll(0, input);
      dataIn.ref.cbData = input.length;
      dataIn.ref.pbData = inputBuffer;

      final result = CryptUnprotectData(
        dataIn,
        null,
        null,
        null,
        _cryptProtectUiForbidden,
        dataOut,
      );
      if (!result.value) {
        throw WindowsException(result.error.toHRESULT());
      }

      return Uint8List.fromList(
        dataOut.ref.pbData.asTypedList(dataOut.ref.cbData),
      );
    } finally {
      if (dataOut.ref.pbData != nullptr) {
        LocalFree(HLOCAL(dataOut.ref.pbData));
      }
      calloc.free(inputBuffer);
      calloc.free(dataIn);
      calloc.free(dataOut);
    }
  }
}
