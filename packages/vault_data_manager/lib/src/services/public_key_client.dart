import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

/// Utilities for configuring a Dio instance used to fetch public keys with
/// in-memory caching, in-flight request coalescing, and dio_cache_interceptor.
class PublicKeyClient {
  static const Duration _defaultCacheTtl = Duration(minutes: 10);
  static const int _defaultCacheMaxEntries = 8;
  static const int _minEntries = 5;
  static const int _cacheEntrySizeBytes = 16 * 1024;

  /// Returns a Dio configured for JWKS fetching and caching.
  static Dio createConfiguredDio({
    Dio? dio,
    Duration cacheTtl = _defaultCacheTtl,
    int cacheMaxEntries = _defaultCacheMaxEntries,
  }) {
    final configuredDio = dio ?? Dio();

    configuredDio.interceptors.removeWhere(
      (interceptor) =>
          interceptor is _PublicKeyCachingInterceptor ||
          interceptor is DioCacheInterceptor ||
          interceptor is _PublicKeyCacheControlInterceptor,
    );

    final cacheOptions = CacheOptions(
      store: _BoundedMemCacheStore(
        maxEntries: cacheMaxEntries,
        maxSize:
            _minimumStoreEntryCount(cacheMaxEntries) * _cacheEntrySizeBytes,
        maxEntrySize: _cacheEntrySizeBytes,
      ),
      policy: CachePolicy.request,
      priority: CachePriority.high,
    );

    configuredDio.interceptors.add(
      _PublicKeyCachingInterceptor(
        cacheOptions: cacheOptions,
        store: cacheOptions.store!,
        ttl: cacheTtl,
        maxEntries: cacheMaxEntries,
      ),
    );
    configuredDio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
    configuredDio.interceptors.add(
      _PublicKeyCacheControlInterceptor(ttl: cacheTtl),
    );

    return configuredDio;
  }

  /// Clears the attached JWKS caches from a configured Dio instance.
  static Future<void> clearCache(Dio dio) async {
    for (final interceptor in dio.interceptors) {
      if (interceptor is _PublicKeyCachingInterceptor) {
        await interceptor.clear();
      }
    }
  }

  static int _minimumStoreEntryCount(int maxEntries) {
    return max(_minEntries, maxEntries + 1);
  }
}

class _MemoryCachedResponse {
  final dynamic data;
  final Map<String, List<String>> headers;
  final int statusCode;
  final String? statusMessage;
  final DateTime expiresAt;

  const _MemoryCachedResponse({
    required this.data,
    required this.headers,
    required this.statusCode,
    required this.statusMessage,
    required this.expiresAt,
  });

  bool get isExpired => !expiresAt.isAfter(clock.now());
}

class _PublicKeyCachingInterceptor extends Interceptor {
  static const _cacheUrlKey = 'publicKeyCacheUrl';
  static const _inFlightCompleterKey = 'publicKeyCacheInFlightCompleter';

  final LinkedHashMap<String, _MemoryCachedResponse> _memoryCache =
      LinkedHashMap<String, _MemoryCachedResponse>();
  final Map<String, Completer<Response<dynamic>>> _inFlightGets =
      <String, Completer<Response<dynamic>>>{};
  final Map<String, _PublicKeyCacheState> _cacheMetadata =
      <String, _PublicKeyCacheState>{};
  final CacheOptions cacheOptions;
  final CacheStore store;
  final Duration ttl;
  final int maxEntries;

  _PublicKeyCachingInterceptor({
    required this.cacheOptions,
    required this.store,
    required this.ttl,
    required this.maxEntries,
  });

  Future<void> clear() async {
    _memoryCache.clear();
    _inFlightGets.clear();
    _cacheMetadata.clear();
    await store.clean();
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method.toUpperCase() != 'GET') {
      handler.next(options);
      return;
    }

    final absoluteUrl = options.uri.toString();
    options.extra[_cacheUrlKey] = absoluteUrl;

    final cachedResponse = _takeFreshMemoryResponse(absoluteUrl);
    if (cachedResponse != null) {
      handler.resolve(_cloneResponse<dynamic>(cachedResponse, options));
      return;
    }

    final inFlightRequest = _inFlightGets[absoluteUrl];
    if (inFlightRequest != null) {
      final response = await inFlightRequest.future;
      handler.resolve(
        _cloneResponse<dynamic>(
          _MemoryCachedResponse(
            data: _cloneData(response.data),
            headers: Map<String, List<String>>.from(response.headers.map),
            statusCode: response.statusCode ?? 200,
            statusMessage: response.statusMessage,
            expiresAt: clock.now().add(ttl),
          ),
          options,
        ),
      );
      return;
    }

    final completer = Completer<Response<dynamic>>();
    _inFlightGets[absoluteUrl] = completer;
    options.extra[_inFlightCompleterKey] = completer;

    final cacheKey = _buildCacheKey(options);
    final cacheState = _cacheMetadata[cacheKey];
    if (cacheState != null &&
        cacheState.isExpired &&
        !cacheState.hasValidator) {
      await store.delete(cacheKey);
      _cacheMetadata.remove(cacheKey);
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final absoluteUrl = response.requestOptions.extra[_cacheUrlKey] as String?;
    if (absoluteUrl != null &&
        response.requestOptions.method.toUpperCase() == 'GET') {
      _storeMemoryResponse(absoluteUrl, response);
    }

    if (response.requestOptions.method.toUpperCase() == 'GET') {
      final wasRevalidated =
          response.requestOptions.headers.containsKey(ifNoneMatchHeader) ||
          response.requestOptions.headers.containsKey(ifModifiedSinceHeader);
      final cameFromNetwork = response.extra[extraFromNetworkKey] == true;

      if (cameFromNetwork || wasRevalidated) {
        final cacheKey =
            response.extra[extraCacheKey] as String? ??
            _buildCacheKey(response.requestOptions);
        final hasValidator =
            (response.headers.value(etagHeader)?.isNotEmpty ?? false) ||
            (response.headers.value(lastModifiedHeader)?.isNotEmpty ?? false);
        _cacheMetadata[cacheKey] = _PublicKeyCacheState(
          expiresAt: clock.now().add(ttl),
          hasValidator: hasValidator,
        );
      }
    }

    _completeInFlight(response.requestOptions, response);

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final absoluteUrl = err.requestOptions.extra[_cacheUrlKey] as String?;
    if (absoluteUrl != null) {
      _inFlightGets.remove(absoluteUrl)?.completeError(err);
    }
    handler.next(err);
  }

  _MemoryCachedResponse? _takeFreshMemoryResponse(String absoluteUrl) {
    final cachedResponse = _memoryCache.remove(absoluteUrl);
    if (cachedResponse == null) {
      return null;
    }

    if (cachedResponse.isExpired) {
      return null;
    }

    _memoryCache[absoluteUrl] = cachedResponse;
    return cachedResponse;
  }

  void _storeMemoryResponse(String absoluteUrl, Response<dynamic> response) {
    _memoryCache.remove(absoluteUrl);
    _memoryCache[absoluteUrl] = _MemoryCachedResponse(
      data: _cloneData(response.data),
      headers: Map<String, List<String>>.from(response.headers.map),
      statusCode: response.statusCode ?? 200,
      statusMessage: response.statusMessage,
      expiresAt: clock.now().add(ttl),
    );

    while (_memoryCache.length > maxEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
  }

  Response<T> _cloneResponse<T>(
    _MemoryCachedResponse cachedResponse,
    RequestOptions requestOptions,
  ) {
    return Response<T>(
      requestOptions: requestOptions,
      data: _cloneData(cachedResponse.data) as T,
      headers: Headers.fromMap(cachedResponse.headers),
      statusCode: cachedResponse.statusCode,
      statusMessage: cachedResponse.statusMessage,
      extra: const {extraFromNetworkKey: false},
    );
  }

  dynamic _cloneData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.fromEntries(
        data.entries.map(
          (entry) => MapEntry(entry.key, _cloneData(entry.value)),
        ),
      );
    }

    if (data is Map) {
      return Map<dynamic, dynamic>.fromEntries(
        data.entries.map(
          (entry) => MapEntry(entry.key, _cloneData(entry.value)),
        ),
      );
    }

    if (data is List) {
      return List<dynamic>.from(data.map(_cloneData));
    }

    return data;
  }

  void _completeInFlight(RequestOptions options, Response<dynamic> response) {
    final absoluteUrl = options.extra[_cacheUrlKey] as String?;
    if (absoluteUrl == null) {
      return;
    }

    final completer = _inFlightGets.remove(absoluteUrl);
    if (completer == null || completer.isCompleted) {
      return;
    }

    completer.complete(response);
  }

  String _buildCacheKey(RequestOptions options) {
    return cacheOptions.keyBuilder(
      url: options.uri,
      headers: options.getFlattenHeaders(),
      body: options.data,
    );
  }
}

class _PublicKeyCacheState {
  final DateTime expiresAt;
  final bool hasValidator;

  const _PublicKeyCacheState({
    required this.expiresAt,
    required this.hasValidator,
  });

  bool get isExpired => !expiresAt.isAfter(clock.now());
}

class _PublicKeyCacheControlInterceptor extends Interceptor {
  final Duration ttl;

  _PublicKeyCacheControlInterceptor({required this.ttl});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.headers.value(cacheControlHeader) == null &&
        response.headers.value(expiresHeader) == null) {
      final cacheControlValue = ttl == Duration.zero
          ? 'no-cache'
          : 'max-age=${ttl.inSeconds}, must-revalidate';
      response.headers.map[cacheControlHeader] = [cacheControlValue];
    }

    handler.next(response);
  }
}

class _BoundedMemCacheStore extends CacheStore {
  final MemCacheStore _delegate;
  final int _maxEntries;
  final LinkedHashSet<String> _keys = LinkedHashSet<String>();

  _BoundedMemCacheStore({
    required int maxEntries,
    required int maxSize,
    required int maxEntrySize,
  }) : _maxEntries = maxEntries,
       _delegate = MemCacheStore(maxSize: maxSize, maxEntrySize: maxEntrySize);

  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool staleOnly = false,
  }) async {
    if (!staleOnly) {
      _keys.clear();
    }
    await _delegate.clean(
      priorityOrBelow: priorityOrBelow,
      staleOnly: staleOnly,
    );
  }

  @override
  Future<void> close() async {
    _keys.clear();
    await _delegate.close();
  }

  @override
  Future<void> delete(String key, {bool staleOnly = false}) async {
    if (!staleOnly) {
      _keys.remove(key);
    }
    await _delegate.delete(key, staleOnly: staleOnly);
  }

  @override
  Future<void> deleteFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async {
    final matches = await getFromPath(pathPattern, queryParams: queryParams);
    for (final response in matches) {
      _keys.remove(response.key);
    }

    await _delegate.deleteFromPath(pathPattern, queryParams: queryParams);
  }

  @override
  Future<bool> exists(String key) => _delegate.exists(key);

  @override
  Future<CacheResponse?> get(String key) async {
    final response = await _delegate.get(key);
    if (response == null) {
      _keys.remove(key);
      return null;
    }

    _touch(key);
    return response;
  }

  @override
  Future<List<CacheResponse>> getFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async {
    final matches = <CacheResponse>[];
    for (final key in _keys.toList(growable: false)) {
      if (!pathExists(key, pathPattern, queryParams: queryParams)) {
        continue;
      }

      final response = await _delegate.get(key);
      if (response == null) {
        _keys.remove(key);
        continue;
      }

      _touch(key);
      matches.add(response);
    }

    return matches;
  }

  @override
  Future<void> set(CacheResponse response) async {
    _touch(response.key);
    await _delegate.set(response);
    await _evictOverflow();
  }

  void _touch(String key) {
    _keys.remove(key);
    _keys.add(key);
  }

  Future<void> _evictOverflow() async {
    while (_keys.length > _maxEntries) {
      final leastRecentlyUsedKey = _keys.first;
      _keys.remove(leastRecentlyUsedKey);
      await _delegate.delete(leastRecentlyUsedKey);
    }
  }
}
