import 'dart:io';

import 'package:bett_box/common/http.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Hosts an update download may ever touch (T56): GitHub itself and
/// its asset-delivery hosts. Every redirect hop is re-checked against
/// this list — a redirect to anywhere else aborts the download.
const updateDownloadHosts = {
  'github.com',
  'api.github.com',
  'objects.githubusercontent.com',
  'release-assets.githubusercontent.com',
  'media.githubusercontent.com',
};

bool isAllowedUpdateUrl(Uri uri) =>
    uri.scheme == 'https' &&
    (updateDownloadHosts.contains(uri.host) ||
        uri.host.endsWith('.githubusercontent.com'));

class UpdateDownloadException implements Exception {
  final String message;

  const UpdateDownloadException(this.message);

  @override
  String toString() => message;
}

Dio _updateDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );
  // Downloads prefer the running core's local proxy (the shared
  // override resolves it); when the core is off they go direct.
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) => AngelaHttpOverrides.handleFindProxy(uri);
      return client;
    },
  );
  return dio;
}

/// Opens [url] following redirects manually so every hop is checked
/// against [isAllowedUpdateUrl]. Returns the final streaming response.
Future<Response<ResponseBody>> _openChecked(
  Dio dio,
  String url, {
  CancelToken? cancelToken,
}) async {
  var current = Uri.parse(url);
  for (var hop = 0; hop <= 5; hop++) {
    if (!isAllowedUpdateUrl(current)) {
      throw UpdateDownloadException('blocked redirect to ${current.host}');
    }
    final response = await dio.get<ResponseBody>(
      current.toString(),
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status >= 300) {
      final location = response.headers.value('location');
      // Drain and discard the redirect body.
      await response.data?.stream.drain<void>();
      if (location == null) {
        throw UpdateDownloadException('redirect without location');
      }
      current = current.resolve(location);
      continue;
    }
    return response;
  }
  throw const UpdateDownloadException('too many redirects');
}

/// Downloads [url] to `dir/fileName` with progress callbacks and
/// cancellation. Partial files are removed on any failure.
Future<File> downloadUpdateAsset({
  required String url,
  required Directory dir,
  required String fileName,
  CancelToken? cancelToken,
  void Function(double progress)? onProgress,
}) async {
  await dir.create(recursive: true);
  final file = File('${dir.path}/$fileName');
  final dio = _updateDio();
  IOSink? sink;
  try {
    final response = await _openChecked(dio, url, cancelToken: cancelToken);
    final total = int.tryParse(response.headers.value('content-length') ?? '');
    sink = file.openWrite();
    var received = 0;
    await for (final chunk in response.data!.stream) {
      if (cancelToken?.isCancelled ?? false) {
        throw DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.cancel,
        );
      }
      received += chunk.length;
      sink.add(chunk);
      if (total != null && total > 0) onProgress?.call(received / total);
    }
    await sink.close();
    sink = null;
    onProgress?.call(1);
    return file;
  } catch (_) {
    await sink?.close();
    if (await file.exists()) await file.delete();
    rethrow;
  } finally {
    dio.close();
  }
}

/// Fetches a small text file (SHA256SUMS) under the same redirect
/// discipline.
Future<String> fetchUpdateText(String url) async {
  final dio = _updateDio();
  try {
    final response = await _openChecked(dio, url);
    final bytes = <int>[];
    await for (final chunk in response.data!.stream) {
      bytes.addAll(chunk);
      if (bytes.length > 1024 * 1024) {
        throw const UpdateDownloadException('text file too large');
      }
    }
    return String.fromCharCodes(bytes);
  } finally {
    dio.close();
  }
}

/// Streams a file through SHA-256 and compares with the expected
/// digest (case-insensitive).
Future<bool> verifyFileSha256(File file, String expectedHex) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString().toLowerCase() == expectedHex.toLowerCase();
}
