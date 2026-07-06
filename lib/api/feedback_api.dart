// 中文注释：问题反馈 API，提供跨模块可复用的提交模型和客户端。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/app_core.dart';

Future<Map<String, dynamic>> Function(Map<String, Object?> body)?
    debugFeedbackResponseOverride;

const feedbackApi = FeedbackApi();

class FeedbackApi {
  const FeedbackApi();

  Future<FeedbackReceipt> submit(FeedbackDraft draft) async {
    final override = debugFeedbackResponseOverride;
    if (override != null) {
      return FeedbackReceipt.fromJson(await override(draft.toJson()));
    }
    final json = await _requestJson(draft.toJson());
    return FeedbackReceipt.fromJson(json);
  }

  Future<Map<String, dynamic>> _requestJson(Map<String, Object?> body) async {
    final base = Uri.parse(apiBaseUrl);
    final uri = base.replace(path: '${base.path}/v1/feedback');
    final bodyBytes = utf8.encode(jsonEncode(body));
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.contentType = ContentType.json;
      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);
      final response =
          await request.close().timeout(const Duration(seconds: 12));
      final raw = await utf8.decodeStream(response);
      final decoded =
          raw.trim().isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      final json =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = json['error'] as Map<String, dynamic>?;
        throw FeedbackApiException(
          (error?['message'] as String?) ?? '请求失败：${response.statusCode}',
        );
      }
      return json;
    } on FeedbackApiException {
      rethrow;
    } on SocketException {
      throw const FeedbackApiException('无法连接服务端。');
    } on TimeoutException {
      throw const FeedbackApiException('服务端响应超时。');
    } finally {
      client.close(force: true);
    }
  }
}

class FeedbackApiException implements Exception {
  const FeedbackApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FeedbackDraft {
  const FeedbackDraft({
    required this.type,
    required this.content,
    required this.contact,
    required this.platform,
    required this.appVersionName,
    required this.appVersionCode,
    required this.deviceInfo,
  });

  final String type;
  final String content;
  final String contact;
  final String platform;
  final String appVersionName;
  final int appVersionCode;
  final String deviceInfo;

  Map<String, Object?> toJson() {
    return {
      'type': type,
      'content': content,
      'contact': contact,
      'platform': platform,
      'appVersionName': appVersionName,
      'appVersionCode': appVersionCode,
      'deviceInfo': deviceInfo,
    };
  }
}

class FeedbackReceipt {
  const FeedbackReceipt({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String status;
  final String createdAt;

  factory FeedbackReceipt.fromJson(Map<String, dynamic> json) {
    final feedback = json['feedback'] as Map<String, dynamic>? ?? {};
    return FeedbackReceipt(
      id: feedback['id'] as String? ?? '',
      status: feedback['status'] as String? ?? '',
      createdAt: feedback['createdAt'] as String? ?? '',
    );
  }
}
