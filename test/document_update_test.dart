import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/data/repositories/compliance_document_repository.dart';

class DocumentApi extends ApiClient {
  FormData? sent;
  @override
  Future<Response> patchData(
    String uri,
    dynamic body, {
    CancelToken? cancelToken,
    Map<String, dynamic>? extraHeaders,
  }) async {
    sent = body as FormData;
    return Response(requestOptions: RequestOptions(path: uri), statusCode: 200);
  }
}

class MediaAdapter implements HttpClientAdapter {
  int calls = 0;
  int status = 200;
  final bytes = <int>[37, 80, 68, 70, 45, 49, 46, 55];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    expect(options.headers.containsKey('Authorization'), isFalse);
    return ResponseBody.fromBytes(bytes, status);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late DocumentApi api;
  late MediaAdapter adapter;
  late ComplianceDocumentRepository repository;
  setUp(() {
    api = DocumentApi();
    adapter = MediaAdapter();
    final media = Dio()..httpClientAdapter = adapter;
    repository = ComplianceDocumentRepository(
      apiClient: api,
      mediaClient: media,
    );
  });

  test(
    'expiry change reattaches existing document bytes in multipart request',
    () async {
      await repository.updateDocument(
        documentId: 'permit',
        expiryDate: '2027-10-22',
        existingFileUrl: 'https://cdn.example.com/permit.pdf',
      );
      expect(
        Map.fromEntries(api.sent!.fields),
        {'expiryDate': '2027-10-22'},
      );
      final file = api.sent!.files.single;
      expect(file.key, 'file');
      expect(file.value.filename, 'permit.pdf');
      expect(
        await file.value.finalize().expand((bytes) => bytes).toList(),
        adapter.bytes,
      );
      expect(adapter.calls, 1);
    },
  );

  test('newly selected file takes priority over old server image', () async {
    final dir = await Directory.systemTemp.createTemp('moeb_document_test_');
    final file = await File(
      '${dir.path}/new.jpg',
    ).writeAsBytes([255, 216, 255, 217]);
    try {
      await repository.updateDocument(
        documentId: 'permit',
        expiryDate: '2027-10-22',
        file: file,
        existingFileUrl: 'https://cdn.example.com/old.jpg',
      );
      expect(adapter.calls, 0);
      expect(api.sent!.files.single.value.filename, 'new.jpg');
      expect(
        await api.sent!.files.single.value
            .finalize()
            .expand((bytes) => bytes)
            .toList(),
        [255, 216, 255, 217],
      );
    } finally {
      await file.delete();
      await dir.delete();
    }
  });

  test('missing image blocks update instead of sending expiry alone', () async {
    await expectLater(
      repository.updateDocument(documentId: 'permit', expiryDate: '2027-10-22'),
      throwsArgumentError,
    );
    expect(api.sent, isNull);
  });

  test('failed existing file download never sends expiry-only PATCH', () async {
    adapter.status = 404;
    await expectLater(
      repository.updateDocument(
        documentId: 'permit',
        expiryDate: '2027-10-22',
        existingFileUrl: 'https://cdn.example.com/missing.jpg',
      ),
      throwsA(isA<DioException>()),
    );
    expect(api.sent, isNull);
  });
}
