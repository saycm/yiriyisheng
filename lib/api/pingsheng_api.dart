// 中文注释：后端接口客户端，负责认证、更新检查和服务端通信。

part of '../auth/auth.dart';

/// 服务端 HTTP 客户端：封装认证、Token 刷新、用户信息和 App 更新检查。
class _PingShengApi {
  const _PingShengApi();

  static const _responseTimeout = Duration(seconds: 12);
  static const _maxResponseBodyBytes = 1024 * 1024;

  // 检查 App 更新：带上当前平台和版本号，返回最新版本信息。
  Future<_UpdateInfo> checkUpdate() async {
    final json = await _requestJson(
      'GET',
      '/v1/app/update',
      query: {
        'platform': 'android',
        'versionCode': appVersionCode.toString(),
        'versionName': appVersionName,
      },
    );
    return _UpdateInfo.fromJson(json);
  }

  // 邮箱注册，成功后返回登录会话。
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

  // 手机号注册，成功后返回登录会话。
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

  // 邮箱登录。
  Future<_AuthSession> loginEmail({
    required String email,
    required String password,
  }) {
    return _auth('/v1/auth/login/email', {
      'email': email,
      'password': password,
    });
  }

  // 手机号登录。
  Future<_AuthSession> loginPhone({
    required String phone,
    required String password,
  }) {
    return _auth('/v1/auth/login/phone', {
      'phone': phone,
      'password': password,
    });
  }

  // 用 refresh token 换取新的访问令牌。
  Future<_AuthSession> refresh(String refreshToken) {
    return _auth('/v1/auth/refresh', {'refreshToken': refreshToken});
  }

  // 读取当前登录用户信息。
  Future<_AuthUser> me(String accessToken) async {
    final json = await _requestJson(
      'GET',
      '/v1/me',
      accessToken: accessToken,
    );
    return _AuthUser.fromJson(json['user'] as Map<String, dynamic>? ?? {});
  }

  // 认证类接口的公共封装：POST 后把响应解析成会话。
  Future<_AuthSession> _auth(String path, Map<String, Object?> body) async {
    final json = await _requestJson('POST', path, body: body);
    return _AuthSession.fromJson(json);
  }

  // 统一的 JSON 请求方法：拼 URL、带 Token、编码请求体并翻译网络错误。
  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, Object?>? body,
    String? accessToken,
  }) async {
    // 统一拼接基础地址、请求头、JSON 编码和错误翻译，页面层只处理业务结果。
    final base = Uri.parse(apiBaseUrl);
    final uri = base.replace(
      path: '${base.path}$path',
      queryParameters: query,
    );
    final bodyBytes = body == null ? null : utf8.encode(jsonEncode(body));
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);

    Future<Map<String, dynamic>> performRequest() async {
      final request =
          await (method == 'GET' ? client.getUrl(uri) : client.postUrl(uri));
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
      final response = await request.close();
      final raw = await _readResponseBody(response);
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
    }

    try {
      return await performRequest().timeout(_responseTimeout);
    } on SocketException {
      throw const _ApiException('无法连接服务端。');
    } on TimeoutException {
      throw const _ApiException('服务端响应超时。');
    } finally {
      client.close(force: true);
    }
  }

  // 读取响应体，并限制最大字节数防止内存被超大响应占满。
  Future<String> _readResponseBody(HttpClientResponse response) async {
    // 限制响应体大小，避免服务端异常返回超大内容拖垮内存。
    if (response.contentLength > _maxResponseBodyBytes) {
      throw const _ApiException('服务端响应过大。');
    }

    final bytes = <int>[];
    await for (final chunk in response) {
      if (chunk.length > _maxResponseBodyBytes - bytes.length) {
        throw const _ApiException('服务端响应过大。');
      }
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }
}

/// 服务端接口返回的业务异常，携带可选的错误码。
class _ApiException implements Exception {
  const _ApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// App 更新检查结果：最新版本、是否强制更新和更新说明。
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

/// 当前登录用户的基本信息。
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

  // 用户信息序列化，供本地会话存储使用。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'displayName': displayName,
    };
  }
}

/// 一次登录会话：访问令牌、刷新令牌和用户信息。
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

  // 复制会话并替换用户信息（刷新用户资料时使用）。
  _AuthSession copyWith({_AuthUser? user}) {
    return _AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user ?? this.user,
    );
  }

  // 会话序列化，供原生加密存储使用。
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }
}

/// 登录态存储：通过 MethodChannel 交给 Android 原生加密存储。
class _AuthSessionStore {
  const _AuthSessionStore();

  // 真实存储在 Android 原生层，Dart 侧只通过通道读写序列化后的会话。
  static const _channel = MethodChannel('pingsheng_life/auth_session');

  // 从原生加密存储读取登录会话，失败时当作未登录。
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

  // 把登录会话写入原生加密存储。
  Future<void> save(_AuthSession session) async {
    try {
      await _channel.invokeMethod<void>(
          'saveAuthSession', jsonEncode(session.toJson()));
    } catch (_) {
      // 登录态保存失败不阻止本次进入 App；下次启动会重新登录。
    }
  }

  // 清除原生存储中的登录会话。
  Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clearAuthSession');
    } catch (_) {
      // 忽略平台存储清理失败。
    }
  }
}
