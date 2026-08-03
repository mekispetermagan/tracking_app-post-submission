import 'dart:typed_data';

import 'package:agu_frontend/storage/storage.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'fetches compressed photo bytes and forwards the chosen filename',
    () async {
      String? savedName;
      Uint8List? savedBytes;
      final service = PhotoDownloadService(
        client: MockClient(
          (request) async => http.Response.bytes([1, 2, 3], 200),
        ),
        saveBytes: ({required fileName, required bytes}) async {
          savedName = fileName;
          savedBytes = bytes;
          return '';
        },
      );

      final bytes = await service.fetch('https://example.com/photo.jpg');
      await service.save(fileName: 'session_photo.jpg', bytes: bytes);

      expect(savedName, 'session_photo.jpg');
      expect(savedBytes, [1, 2, 3]);
    },
  );

  test(
    'reports failed fetches and treats picker cancellation separately',
    () async {
      final failedFetch = PhotoDownloadService(
        client: MockClient((request) async => http.Response('', 404)),
      );
      expect(
        failedFetch.fetch('https://example.com/missing.jpg'),
        throwsA(isA<PhotoDownloadException>()),
      );

      final cancelledSave = PhotoDownloadService(
        saveBytes: ({required fileName, required bytes}) async {
          throw FileSaverCancelledException();
        },
      );
      expect(
        cancelledSave.save(fileName: 'photo.jpg', bytes: Uint8List(0)),
        throwsA(isA<PhotoDownloadCancelled>()),
      );
    },
  );
}
