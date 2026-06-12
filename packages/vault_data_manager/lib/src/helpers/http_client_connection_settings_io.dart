import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Configures the Dio HTTP client's connection idle timeout.
void configureHttpClientConnectionSettings(
  Dio dio, {
  required Duration idleTimeout,
}) {
  if (dio.httpClientAdapter is! IOHttpClientAdapter) {
    return;
  }

  final existingAdapter = dio.httpClientAdapter as IOHttpClientAdapter;
  final previousCreateHttpClient = existingAdapter.createHttpClient;

  existingAdapter.createHttpClient = () {
    final client = previousCreateHttpClient?.call() ?? HttpClient();
    client.idleTimeout = idleTimeout;
    return client;
  };
}
