import 'dart:typed_data';

import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:http/http.dart' as http;

typedef PhotoBytesSaver =
    Future<String> Function({
      required String fileName,
      required Uint8List bytes,
    });

class PhotoDownloadException implements Exception {
  const PhotoDownloadException();
}

class PhotoDownloadCancelled implements Exception {
  const PhotoDownloadCancelled();
}

class PhotoDownloadService {
  PhotoDownloadService({http.Client? client, PhotoBytesSaver? saveBytes})
    : _client = client ?? http.Client(),
      _saveBytes = saveBytes ?? FlutterFileSaver().writeFileAsBytes;

  final http.Client _client;
  final PhotoBytesSaver _saveBytes;

  Future<Uint8List> fetch(String imageUrl) async {
    final response = await _client.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw const PhotoDownloadException();
    }
    return response.bodyBytes;
  }

  Future<void> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      await _saveBytes(fileName: fileName, bytes: bytes);
    } on FileSaverCancelledException {
      throw const PhotoDownloadCancelled();
    } catch (error) {
      if (error is PhotoDownloadCancelled) rethrow;
      throw const PhotoDownloadException();
    }
  }

  void dispose() {
    _client.close();
  }
}
