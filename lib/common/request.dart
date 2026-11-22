import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

import 'release_updates.dart';

class _LimitedByteSink extends ByteConversionSinkBase {
  _LimitedByteSink(this.maxBytes);

  final int maxBytes;
  final BytesBuilder _builder = BytesBuilder(copy: false);

  Uint8List takeBytes() => _builder.takeBytes();

  @override
  void add(List<int> chunk) {
    if (_builder.length + chunk.length > maxBytes) {
      throw const FormatException('Decompressed data exceeds limit');
    }
    _builder.add(chunk);
  }

  @override
  void close() {}
}

class Request {
  static const _maxDecompressedBytes = 64 * 1024 * 1024;

  late final Dio _dio;
  late final Dio _clashDio;
  String? userAgent;

  Request() {
    _dio = Dio(BaseOptions(headers: {'User-Agent': browserUa}));
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.autoUncompress = false;
        return client;
      },
    );
    _clashDio = Dio();
    _clashDio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.autoUncompress = false;
        client.findProxy = (Uri uri) {
          client.userAgent = globalState.ua;
          return AngelaHttpOverrides.handleFindProxy(uri);
        };
        return client;
      },
    );
    // T281 (audit AM-05): the subscription download chain must never
    // reach link-local or cloud metadata destinations. The redirect
    // loop below re-checks every hop; this interceptor covers the
    // initial request (and re-checks each hop as it is issued).
    _clashDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final reason = DownloadTargetGuard.blockFor(options.uri);
          if (reason == null) {
            handler.next(options);
            return;
          }
          handler.reject(
            _blockedTargetException(options.uri, reason, options),
            true,
          );
        },
      ),
    );
  }

  DioException _blockedTargetException(
    Uri uri,
    DownloadTargetBlock reason, [
    RequestOptions? requestOptions,
  ]) {
    return DioException(
      requestOptions: requestOptions ?? RequestOptions(path: uri.toString()),
      type: DioExceptionType.badResponse,
      error: BlockedDownloadTargetException(uri, reason),
      message: 'Subscription download target is blocked: $uri',
    );
  }

  /// Status codes the manual redirect loop follows, mirroring the
  /// set dart:io's HttpClient follows automatically.
  static bool _isRedirectStatus(int? status) =>
      status == 301 ||
      status == 302 ||
      status == 303 ||
      status == 307 ||
      status == 308;

  static bool _acceptRedirectResponses(int? status) =>
      status != null && status < 400;

  /// Sends [send] for [url] and follows redirects manually so every
  /// hop is validated by [DownloadTargetGuard] before the request
  /// goes out (T281): dart:io follows redirects inside the client,
  /// where no per-hop check is possible. Callers must disable the
  /// client's own redirect following and accept 3xx responses (see
  /// [_acceptRedirectResponses]). The hop limit matches the dart:io
  /// default of 5.
  Future<Response> _sendFollowingRedirects(
    String url,
    Future<Response> Function(String url) send,
  ) async {
    var current = url;
    final redirects = <RedirectRecord>[];
    while (true) {
      final uri = Uri.parse(current);
      final reason = DownloadTargetGuard.blockFor(uri);
      if (reason != null) {
        throw _blockedTargetException(uri, reason);
      }
      final response = await send(current);
      final location = response.headers.value(HttpHeaders.locationHeader);
      if (!_isRedirectStatus(response.statusCode) || location == null) {
        response.isRedirect = redirects.isNotEmpty;
        response.redirects = redirects;
        return response;
      }
      if (redirects.length >= 5) {
        throw DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.unknown,
          error: HttpException('Redirect limit exceeded', uri: uri),
          message: 'Too many redirects for $url',
        );
      }
      final next = uri.resolve(location);
      redirects.add(
        RedirectRecord(
          response.statusCode!,
          response.requestOptions.method,
          next,
        ),
      );
      current = next.toString();
    }
  }

  Uint8List _decodeWithLimit(
    Converter<List<int>, List<int>> decoder,
    Uint8List input,
  ) {
    final sink = _LimitedByteSink(_maxDecompressedBytes);
    final inputSink = decoder.startChunkedConversion(sink);
    inputSink.add(input);
    inputSink.close();
    return sink.takeBytes();
  }

  Uint8List _decompressIfNeeded(Uint8List bytes, Headers headers) {
    final encodings =
        headers['content-encoding']?.map((e) => e.toLowerCase()).toList() ?? [];
    final encodingStr = encodings.join(', ');
    var wantGzip = encodingStr.contains('gzip');
    var wantDeflate = encodingStr.contains('deflate');

    var current = bytes;
    for (var i = 0; i < 4; i++) {
      final isGzipMagic =
          current.length >= 2 && current[0] == 0x1f && current[1] == 0x8b;
      if (wantGzip || isGzipMagic) {
        if (!isGzipMagic) {
          break;
        }
        try {
          current = _decodeWithLimit(gzip.decoder, current);
          wantGzip = false;
          continue;
        } catch (_) {
          break;
        }
      }
      if (wantDeflate) {
        try {
          current = _decodeWithLimit(zlib.decoder, current);
          wantDeflate = false;
          continue;
        } catch (_) {
          try {
            current = _decodeWithLimit(ZLibDecoder(raw: true), current);
            wantDeflate = false;
            continue;
          } catch (_) {
            break;
          }
        }
      }
      break;
    }
    return current;
  }

  Uint8List _bytesFromResponse(Response response) {
    final data = response.data;
    if (data is Uint8List) return data;
    return Uint8List.fromList((data as List).cast<int>());
  }

  Future<({File file, String? fileName})> _localFileForUrl(String url) async {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty && uri.host.isEmpty) {
      throw Exception('Empty file path in file url: $url');
    }

    final filePath = _buildFilePath(uri, segments);
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Local file not found: $filePath');
    }
    return (file: file, fileName: segments.lastOrNull);
  }

  Headers? _fileHeaders(String? fileName) {
    if (fileName == null) return null;
    return Headers.fromMap({
      'content-disposition': [
        'attachment; filename*=UTF-8\'\'${Uri.encodeComponent(fileName)}',
      ],
    });
  }

  Future<Response> _getFileResponseForUrl(
    String url,
    ResponseType responseType,
  ) async {
    final local = await _localFileForUrl(url);
    final bytes = await local.file.readAsBytes();
    return _buildResponseFromBytes(
      url: url,
      bytes: bytes,
      responseType: responseType,
      fileName: local.fileName,
    );
  }

  String _buildFilePath(Uri uri, List<String> segments) {
    if (segments.isNotEmpty && segments.first.contains(':')) {
      return segments.join('/');
    }
    final host = uri.host;
    if (host.isNotEmpty && host.toLowerCase() != 'localhost') {
      if (host.length == 1 && RegExp(r'^[a-zA-Z]$').hasMatch(host)) {
        return '$host:/${segments.join('/')}';
      }
      return '//$host/${segments.join('/')}';
    }
    return '/${segments.join('/')}';
  }

  Response _buildResponseFromBytes({
    required String url,
    required Uint8List bytes,
    required ResponseType responseType,
    String? fileName,
  }) {
    final requestOptions = RequestOptions(path: url);
    final headers = _fileHeaders(fileName);
    if (responseType == ResponseType.plain) {
      return Response(
        requestOptions: requestOptions,
        data: utf8.decode(bytes, allowMalformed: true),
        statusCode: HttpStatus.ok,
        headers: headers,
      );
    }
    return Response(
      requestOptions: requestOptions,
      data: bytes,
      statusCode: HttpStatus.ok,
      headers: headers,
    );
  }

  (String, Map<String, dynamic>) _authorizedRequest(String url) {
    String? userInfo;
    String requestUrl = url;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      final schemeEnd = url.indexOf('://') + 3;
      final slashIndex = url.indexOf('/', schemeEnd);
      final questionIndex = url.indexOf('?', schemeEnd);
      final hashIndex = url.indexOf('#', schemeEnd);
      var authorityEnd = url.length;
      if (slashIndex != -1) authorityEnd = slashIndex;
      if (questionIndex != -1 && questionIndex < authorityEnd) {
        authorityEnd = questionIndex;
      }
      if (hashIndex != -1 && hashIndex < authorityEnd) {
        authorityEnd = hashIndex;
      }
      final atIndex = url.lastIndexOf('@', authorityEnd - 1);
      if (atIndex >= schemeEnd) {
        userInfo = url.substring(schemeEnd, atIndex);
        requestUrl = url.substring(0, schemeEnd) + url.substring(atIndex + 1);
      }
    }

    final headers = <String, dynamic>{'Connection': 'close'};
    if (userInfo != null && userInfo.isNotEmpty) {
      final auth = base64Encode(utf8.encode(userInfo));
      headers['Authorization'] = 'Basic $auth';
    }

    return (requestUrl, headers);
  }

  Future<T> _withPlainEncodingRetry<T>(
    Map<String, dynamic> headers,
    Future<T> Function(Map<String, dynamic> requestHeaders) send,
  ) async {
    try {
      return await send(headers);
    } on DioException catch (e) {
      final error = e.error;
      if (error is! HttpException ||
          !error.message.contains(HttpHeaders.contentEncodingHeader)) {
        rethrow;
      }
      return send({...headers, HttpHeaders.acceptEncodingHeader: 'identity'});
    }
  }

  Future<({String path, Headers? headers, bool remote})> fetchProfileSource(
    String url,
    String downloadPath,
  ) async {
    if (url.isFileUrl) {
      final local = await _localFileForUrl(url);
      await local.file.copy(downloadPath);
      return (
        path: downloadPath,
        headers: _fileHeaders(local.fileName),
        remote: false,
      );
    }
    final (requestUrl, headers) = _authorizedRequest(url);
    final response = await _withPlainEncodingRetry(
      headers,
      (requestHeaders) => _sendFollowingRedirects(
        requestUrl,
        (target) => _clashDio.download(
          target,
          downloadPath,
          options: Options(
            headers: requestHeaders,
            followRedirects: false,
            validateStatus: _acceptRedirectResponses,
          ),
        ),
      ),
    );
    return (path: downloadPath, headers: response.headers, remote: true);
  }

  Future<Response> _getResponseForUrl(
    String url,
    ResponseType responseType,
  ) async {
    if (url.isFileUrl) {
      return _getFileResponseForUrl(url, responseType);
    }

    final (requestUrl, headers) = _authorizedRequest(url);
    final response = await _withPlainEncodingRetry(
      headers,
      (requestHeaders) => _sendFollowingRedirects(
        requestUrl,
        (target) => _clashDio.get(
          target,
          options: Options(
            responseType: ResponseType.bytes,
            headers: requestHeaders,
            followRedirects: false,
            validateStatus: _acceptRedirectResponses,
          ),
        ),
      ),
    );

    final rawBytes = _bytesFromResponse(response);
    final decompressedBytes = _decompressIfNeeded(rawBytes, response.headers);

    if (responseType == ResponseType.plain) {
      final text = utf8.decode(decompressedBytes, allowMalformed: true);
      return Response(
        requestOptions: response.requestOptions,
        data: text,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        isRedirect: response.isRedirect,
        redirects: response.redirects,
        extra: response.extra,
        headers: response.headers,
      );
    } else {
      return Response(
        requestOptions: response.requestOptions,
        data: decompressedBytes,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        isRedirect: response.isRedirect,
        redirects: response.redirects,
        extra: response.extra,
        headers: response.headers,
      );
    }
  }

  Future<Response> getTextResponseForUrl(String url) async {
    return _getResponseForUrl(url, ResponseType.plain);
  }

  Future<MemoryImage?> getImage(String url) async {
    if (url.isEmpty) return null;
    final response = await _dio.get<Uint8List>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) return null;
    final bytes = _decompressIfNeeded(data, response.headers);
    return MemoryImage(bytes);
  }

  Future<Uint8List?> getBytes(String url, {CancelToken? cancelToken}) async {
    final response = await _dio.get<Uint8List>(
      url,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) return null;
    return _decompressIfNeeded(data, response.headers);
  }

  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final release = await ReleaseUpdates(repository: repository).latest();
      if (release == null) return null;
      final tag = release['tag_name'] as String;
      final version = globalState.packageInfo.version;
      if (utils.compareVersions(tag, version) <= 0) return null;
      return release;
    } catch (e) {
      commonPrint.warn('Check update failed: ${e.formatErrorLog}');
    }
    return null;
  }

  // AngelaMihomo (chain.26, T100): exit-IP discovery uses only
  // Cloudflare trace echo endpoints — the response is generated by
  // Cloudflare's edge and carries just the caller's IP and country
  // code. All geolocation enrichment (country, ASN, org) is resolved
  // locally by the core; no third-party geo service is ever queried
  // and no queried IP leaves the device for enrichment.
  final List<String> _exitIpSources = [
    'https://www.cloudflare.com/cdn-cgi/trace',
    'https://ip.sb/cdn-cgi/trace',
    'https://api.ip.sb/cdn-cgi/trace',
  ];

  /// Test seam: the network-detection tests drive [checkIp] against a
  /// loopback fake instead of the real trace endpoints (which are all
  /// HTTPS and cannot be served by the fake proxy). Production code
  /// never sets this.
  @visibleForTesting
  List<String>? exitIpSourcesOverride;

  final List<String> _domesticIpSources = [
    'https://www.qualcomm.cn/cdn-cgi/trace',
    'https://www.teamviewer.cn/cdn-cgi/trace',
    'https://www.cloudflare.com/cdn-cgi/trace',
  ];

  Future<Result<IpInfo?>> _checkIpFromSources(
    List<String> sources,
    CancelToken? cancelToken,
    Duration? timeout, {
    void Function(IpInfo info)? onUpdate,
    String? proxy,
  }) async {
    final effectiveTimeout = timeout ?? const Duration(seconds: 5);

    final dio = Dio(
      BaseOptions(
        receiveTimeout: effectiveTimeout,
        connectTimeout: effectiveTimeout,
        sendTimeout: effectiveTimeout,
      ),
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.autoUncompress = false;
        client.connectionTimeout = effectiveTimeout;
        if (proxy != null) client.findProxy = (_) => proxy;
        return client;
      },
    );

    final Completer<Result<IpInfo?>> firstCompleter = Completer();
    IpInfo? primaryInfo;
    IpInfo? fallbackInfo;
    int completedCount = 0;
    Timer? cleanupTimer;

    void cleanup() {
      cleanupTimer?.cancel();
      cleanupTimer = null;
      dio.close(force: true);
    }

    cleanupTimer = Timer(effectiveTimeout, cleanup);
    cancelToken?.whenCancel.then((_) => cleanup());

    void checkAllFinished() {
      completedCount++;
      if (completedCount == sources.length) {
        if (!firstCompleter.isCompleted) {
          final res = primaryInfo ?? fallbackInfo;
          if (res != null) onUpdate?.call(res);
          firstCompleter.complete(Result.success(res));
        }
        cleanup();
      }
    }

    for (int i = 0; i < sources.length; i++) {
      final url = sources[i];
      final isPrimary = i == 0;
      dio
          .get<Uint8List>(
            url,
            cancelToken: cancelToken,
            options: Options(responseType: ResponseType.bytes),
          )
          .then((res) {
            if (res.statusCode == HttpStatus.ok && res.data != null) {
              try {
                final text = utf8
                    .decode(
                      _decompressIfNeeded(_bytesFromResponse(res), res.headers),
                      allowMalformed: true,
                    )
                    .trim();
                IpInfo? ipInfo;
                if (text.startsWith('{')) {
                  final jsonMap = json.decode(text);
                  if (jsonMap is Map<String, dynamic>) {
                    ipInfo = IpInfo.fromJson(jsonMap);
                  }
                } else {
                  ipInfo = IpInfo.fromCloudflareTrace(text);
                }

                if (ipInfo != null) {
                  if (isPrimary) {
                    primaryInfo = ipInfo;
                    onUpdate?.call(ipInfo);
                    if (!firstCompleter.isCompleted) {
                      firstCompleter.complete(Result.success(ipInfo));
                    }
                  } else {
                    fallbackInfo = ipInfo;
                    if (sources.length == 1) {
                      onUpdate?.call(ipInfo);
                      if (!firstCompleter.isCompleted) {
                        firstCompleter.complete(Result.success(ipInfo));
                      }
                    }
                  }
                }
              } catch (_) {}
            }
            checkAllFinished();
          })
          .catchError((e) {
            if (e is DioException && e.type == DioExceptionType.cancel) {
              if (!firstCompleter.isCompleted) {
                firstCompleter.complete(Result.error('cancelled'));
              }
            }
            checkAllFinished();
          });
    }

    return await firstCompleter.future.timeout(
      effectiveTimeout,
      onTimeout: () {
        cleanup();
        cancelToken?.cancel('timeout');
        final res = primaryInfo ?? fallbackInfo;
        if (res != null) {
          return Result.success(res);
        }
        return Result.error('timeout');
      },
    );
  }

  Future<Result<IpInfo?>> _enrichLocally(Result<IpInfo?> res) async {
    final info = res.data;
    if (res.isError || info == null || info.ip.isEmpty) return res;
    // Enrichment is best-effort: a slow or unavailable core bridge
    // must never stall the detection itself, so bound the wait and
    // keep the trace-only result on any failure.
    try {
      final geo = await clashCore
          .getIpGeo(info.ip)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (geo == null) return res;
      return Result.success(info.merge(geo));
    } catch (_) {
      return res;
    }
  }

  Future<Result<IpInfo?>> checkIp({
    CancelToken? cancelToken,
    Duration? timeout,
    void Function(IpInfo info)? onUpdate,
    String? proxy,
  }) async {
    final res = await _checkIpFromSources(
      exitIpSourcesOverride ?? _exitIpSources,
      cancelToken,
      timeout,
      onUpdate: onUpdate,
      proxy: proxy,
    );
    return _enrichLocally(res);
  }

  Future<Result<IpInfo?>> checkIpDomestic({
    CancelToken? cancelToken,
    Duration? timeout,
    void Function(IpInfo info)? onUpdate,
  }) async {
    final res = await _checkIpFromSources(
      _domesticIpSources,
      cancelToken,
      timeout,
      onUpdate: onUpdate,
    );
    return _enrichLocally(res);
  }

  Future<Map<String, dynamic>?> readIpCache(String cacheKey) async {
    try {
      final raw = await clashCore.storeGet(StoreSpace.ip, cacheKey);
      if (raw.isEmpty) return null;
      final decoded = json.decode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeIpCache(String cacheKey, Map<String, dynamic> data) async {
    try {
      await clashCore.storeSet(StoreSpace.ip, cacheKey, data);
    } catch (_) {}
  }

  String _ipDetailCacheKey(String ip) => ip;

  Future<IpInfo?> readIpDetailCache(String ip) async {
    try {
      final cached = await readIpCache(_ipDetailCacheKey(ip));
      return cached == null ? null : IpInfo.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  // AngelaMihomo (chain.26, T100): per-IP detail is answered entirely
  // by the core's local GeoIP/ASN databases. The queried IP is never
  // sent to a third-party geo service; when the local databases have
  // no entry the lookup reports failure instead of going online.
  Future<Result<IpInfo?>> queryIpDetail(
    String ip, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      return Result.error('cancelled');
    }
    final cached = await readIpDetailCache(ip);
    if (cached != null) return Result.success(cached);

    try {
      final geo = await clashCore
          .getIpGeo(ip)
          .timeout(timeout ?? const Duration(seconds: 5), onTimeout: () => null);
      if (geo == null) return Result.error('query failed');
      await writeIpCache(_ipDetailCacheKey(ip), geo.toJson());
      return Result.success(geo);
    } catch (e) {
      return Result.error(e.toString());
    }
  }

  Future<IpRisk?> readIpRiskCache(String ip) async {
    try {
      final cached = await readIpCache('risk_$ip');
      return cached == null ? null : IpRisk.fromJson(cached).normalized;
    } catch (_) {
      return null;
    }
  }

  Future<Result<IpRisk?>> queryIpRisk(
    String ip, {
    bool force = false,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = 'risk_$ip';
    if (!force) {
      final cached = await readIpRiskCache(ip);
      if (cached != null) return Result.success(cached);
    }
    const timeout = Duration(seconds: 10);
    try {
      final res = await _dio.get<List<int>>(
        'https://scamalytics.com/ip/${Uri.encodeComponent(ip)}',
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.bytes,
          connectTimeout: timeout,
          receiveTimeout: timeout,
          sendTimeout: timeout,
        ),
      );
      final data = res.data;
      if (res.statusCode != HttpStatus.ok || data == null) {
        return Result.error('query failed');
      }
      final risk = await Isolate.run(() => parseScamalyticsBytes(ip, data));
      if (risk == null) return Result.error('parse failed');
      await writeIpCache(cacheKey, risk.toJson());
      return Result.success(risk);
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        return Result.error('cancelled');
      }
      return Result.error(e.toString());
    }
  }
}

final request = Request();
