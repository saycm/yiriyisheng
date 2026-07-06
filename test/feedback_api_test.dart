// 中文注释：反馈 API 模型测试，验证提交回执解析稳定。

import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/api/feedback_api.dart';

void main() {
  test('feedback receipt parses server response', () {
    final receipt = FeedbackReceipt.fromJson({
      'feedback': {
        'id': 'fb-1',
        'status': 'pending',
        'createdAt': '2026-07-06T10:00:00Z',
      },
    });

    expect(receipt.id, 'fb-1');
    expect(receipt.status, 'pending');
    expect(receipt.createdAt, '2026-07-06T10:00:00Z');
  });

  test('feedback draft serializes app metadata', () {
    final draft = FeedbackDraft(
      type: '问题',
      content: '小组件显示不全',
      contact: '微信 saycm',
      platform: 'android',
      appVersionName: '1.0.60',
      appVersionCode: 61,
      deviceInfo: 'Android',
    );

    expect(draft.toJson(), {
      'type': '问题',
      'content': '小组件显示不全',
      'contact': '微信 saycm',
      'platform': 'android',
      'appVersionName': '1.0.60',
      'appVersionCode': 61,
      'deviceInfo': 'Android',
    });
  });
}
