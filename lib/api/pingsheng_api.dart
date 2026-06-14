part of '../main.dart';

class _PingShengApi {
  const _PingShengApi();

  Future<_UpdateInfo> checkUpdate() async {
    final json = await _requestJson(
      'GET',
      '/v1/app/update',
      query: {
        'platform': 'android',
        'versionCode': _appVersionCode.toString(),
        'versionName': _appVersionName,
      },
    );
    return _UpdateInfo.fromJson(json);
  }

  Future<_AuthSession> registerEmail({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _auth('/v1/auth/register/email', {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
  }

  Future<_AuthSession> registerPhone({
    required String phone,
    required String password,
    required String displayName,
  }) {
    return _auth('/v1/auth/register/phone', {
      'phone': phone,
      'password': password,
      'displayName': displayName,
    });
  }

  Future<_AuthSession> loginEmail({
    required String email,
    required String password,
  }) {
    return _auth('/v1/auth/login/email', {
      'email': email,
      'password': password,
    });
  }

  Future<_AuthSession> loginPhone({
    required String phone,
    required String password,
  }) {
    return _auth('/v1/auth/login/phone', {
      'phone': phone,
      'password': password,
    });
  }

  Future<_AuthSession> refresh(String refreshToken) {
    return _auth('/v1/auth/refresh', {'refreshToken': refreshToken});
  }

  Future<_AuthUser> me(String accessToken) async {
    final json = await _requestJson(
      'GET',
      '/v1/me',
      accessToken: accessToken,
    );
    return _AuthUser.fromJson(json['user'] as Map<String, dynamic>? ?? {});
  }

  Future<_AuthSession> _auth(String path, Map<String, Object?> body) async {
    final json = await _requestJson('POST', path, body: body);
    return _AuthSession.fromJson(json);
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, Object?>? body,
    String? accessToken,
  }) async {
    final base = Uri.parse(_apiBaseUrl);
    final uri = base.replace(
      path: '${base.path}$path',
      queryParameters: query,
    );
    final bodyBytes = body == null ? null : utf8.encode(jsonEncode(body));
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = method == 'GET'
          ? await client.getUrl(uri)
          : await client.postUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      if (accessToken != null) {
        request.headers
            .set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      }
      if (bodyBytes != null) {
        request.headers.contentType = ContentType.json;
        request.contentLength = bodyBytes.length;
        request.add(bodyBytes);
      }
      final response =
          await request.close().timeout(const Duration(seconds: 12));
      final raw = await utf8.decodeStream(response);
      final decoded =
          raw.trim().isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      final json =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = json['error'] as Map<String, dynamic>?;
        throw _ApiException(
          (error?['message'] as String?) ?? '请求失败：${response.statusCode}',
          code: error?['code'] as String?,
        );
      }
      return json;
    } on SocketException {
      throw const _ApiException('无法连接服务端。');
    } on TimeoutException {
      throw const _ApiException('服务端响应超时。');
    } finally {
      client.close(force: true);
    }
  }
}

class _ApiException implements Exception {
  const _ApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class _UpdateInfo {
  const _UpdateInfo({
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.forceUpdate,
    required this.hasUpdate,
    required this.releaseNotes,
    this.downloadUrl,
    this.message,
  });

  final int latestVersionCode;
  final String latestVersionName;
  final bool forceUpdate;
  final bool hasUpdate;
  final String? downloadUrl;
  final String? message;
  final List<String> releaseNotes;

  factory _UpdateInfo.fromJson(Map<String, dynamic> json) {
    final notes = json['releaseNotes'];
    return _UpdateInfo(
      latestVersionCode: (json['latestVersionCode'] as num?)?.toInt() ?? 0,
      latestVersionName: json['latestVersionName'] as String? ?? '-',
      forceUpdate: json['forceUpdate'] == true,
      hasUpdate: json['hasUpdate'] == true,
      downloadUrl: json['downloadUrl'] as String?,
      message: json['message'] as String?,
      releaseNotes: notes is List
          ? notes.map((item) => item.toString()).toList()
          : const [],
    );
  }
}

class _AuthUser {
  const _AuthUser({
    required this.id,
    this.email,
    this.phone,
    this.displayName,
  });

  final String id;
  final String? email;
  final String? phone;
  final String? displayName;

  factory _AuthUser.fromJson(Map<String, dynamic> json) {
    return _AuthUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      displayName: json['displayName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'displayName': displayName,
    };
  }
}

class _AuthSession {
  const _AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final _AuthUser user;

  factory _AuthSession.fromJson(Map<String, dynamic> json) {
    return _AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: _AuthUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  _AuthSession copyWith({_AuthUser? user}) {
    return _AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }
}

class _AuthSessionStore {
  const _AuthSessionStore();

  static const _channel = MethodChannel('pingsheng_life/auth_session');

  Future<_AuthSession?> load() async {
    try {
      final raw = await _channel.invokeMethod<String>('loadAuthSession');
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return _AuthSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(_AuthSession session) async {
    try {
      await _channel.invokeMethod<void>(
          'saveAuthSession', jsonEncode(session.toJson()));
    } catch (_) {
      // 登录态保存失败不阻止本次进入 App；下次启动会重新登录。
    }
  }

  Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clearAuthSession');
    } catch (_) {
      // 忽略平台存储清理失败。
    }
  }
}
