import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void main() {
  const authChannel = MethodChannel('pingsheng_life/auth_session');
  HttpOverrides? previousOverrides;

  setUp(() {
    previousOverrides = HttpOverrides.current;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(authChannel, (call) async => null);
  });

  tearDown(() {
    HttpOverrides.global = previousOverrides;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(authChannel, null);
  });

  testWidgets('response body read has a total timeout', (tester) async {
    final body = StreamController<List<int>>();
    addTearDown(() => unawaited(body.close()));
    HttpOverrides.global = _ResponseHttpOverrides(body.stream);

    await tester.pumpWidget(const PingShengApp(enableAuth: true));
    await tester.pump();

    expect(find.text('正在连接服务端'), findsOneWidget);

    await tester.pump(const Duration(seconds: 11));
    expect(find.text('正在连接服务端'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('正在连接服务端'), findsNothing);
    expect(find.text('创建账号'), findsOneWidget);
    expect(find.text('更新检查暂时不可用，请确认服务器连接。'), findsOneWidget);
  });

  testWidgets('response body read rejects more than one mebibyte',
      (tester) async {
    final json = utf8.encode(
      '{"latestVersionCode":1,"latestVersionName":"1.0.0",'
      '"forceUpdate":false,"hasUpdate":false,"releaseNotes":[]}',
    );
    final body = Stream<List<int>>.fromIterable([
      json,
      List<int>.filled(1024 * 1024, 0x20),
    ]);
    HttpOverrides.global = _ResponseHttpOverrides(body);

    await tester.pumpWidget(const PingShengApp(enableAuth: true));
    await tester.pumpAndSettle();

    expect(find.text('创建账号'), findsOneWidget);
    expect(find.text('更新检查暂时不可用，请确认服务器连接。'), findsOneWidget);
  });

  testWidgets('response header and body share one total timeout',
      (tester) async {
    final json = utf8.encode(
      '{"latestVersionCode":1,"latestVersionName":"1.0.0",'
      '"forceUpdate":false,"hasUpdate":false,"releaseNotes":[]}',
    );
    final body = Stream<List<int>>.fromIterable([json]).asyncMap((chunk) async {
      await Future<void>.delayed(const Duration(seconds: 7));
      return chunk;
    });
    HttpOverrides.global = _ResponseHttpOverrides(
      body,
      responseDelay: const Duration(seconds: 7),
    );

    await tester.pumpWidget(const PingShengApp(enableAuth: true));
    await tester.pump();
    await tester.pump(const Duration(seconds: 13));
    await tester.pump();

    expect(find.text('正在连接服务端'), findsNothing);
    expect(find.text('创建账号'), findsOneWidget);
    expect(find.text('更新检查暂时不可用，请确认服务器连接。'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
  });
}

class _ResponseHttpOverrides extends HttpOverrides {
  _ResponseHttpOverrides(
    this.body, {
    this.responseDelay = Duration.zero,
  });

  final Stream<List<int>> body;
  final Duration responseDelay;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _ResponseHttpClient(body, responseDelay);
}

class _ResponseHttpClient implements HttpClient {
  _ResponseHttpClient(this.body, this.responseDelay);

  final Stream<List<int>> body;
  final Duration responseDelay;

  @override
  Duration? connectionTimeout;

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _ResponseHttpClientRequest(body, responseDelay);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ResponseHttpClientRequest implements HttpClientRequest {
  _ResponseHttpClientRequest(this.body, this.responseDelay);

  final Stream<List<int>> body;
  final Duration responseDelay;
  final HttpHeaders _headers = _TestHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<HttpClientResponse> close() async {
    await Future<void>.delayed(responseDelay);
    return _ResponseHttpClientResponse(body);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ResponseHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _ResponseHttpClientResponse(this.body);

  final Stream<List<int>> body;

  @override
  int get contentLength => -1;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return body.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpHeaders implements HttpHeaders {
  @override
  void set(
    String name,
    Object value, {
    bool preserveHeaderCase = false,
  }) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
