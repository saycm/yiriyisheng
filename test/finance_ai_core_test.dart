import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/modules/finance/finance_ai_core.dart';

void main() {
  test('ai finance core parser can be imported without app ui library', () {
    const parser = AiFinanceJsonParser();

    final bills = parser.parse(
      '{"amount":42,"category":"红包","type":"income","tag":"家人"}',
    );

    expect(bills, hasLength(1));
    expect(bills.single.amount, 42);
    expect(bills.single.type, AiFinanceBillType.income);
    expect(bills.single.tags, ['家人']);
  });

  test('ai finance core defaults stay public for app configuration', () {
    expect(defaultGlmChatEndpoint, contains('/chat/completions'));
    expect(defaultGlmTextModel, isNotEmpty);
  });

  test('ai finance parse strategy keeps json behavior stable', () {
    const strategy = AiFinanceParseStrategy(
      splitMultipleBills: false,
      mergeSameMerchant: false,
      detectTransfers: false,
      extractAccounts: false,
      extractTags: false,
      inferTime: false,
      requireLowConfidenceReview: false,
      noteLength: AiFinanceNoteLength.short,
    );

    final restored = AiFinanceParseStrategy.fromJson(strategy.toJson());

    expect(restored.splitMultipleBills, isFalse);
    expect(restored.mergeSameMerchant, isFalse);
    expect(restored.detectTransfers, isFalse);
    expect(restored.extractAccounts, isFalse);
    expect(restored.extractTags, isFalse);
    expect(restored.inferTime, isFalse);
    expect(restored.requireLowConfidenceReview, isFalse);
    expect(restored.noteLength, AiFinanceNoteLength.short);
    expect(AiFinanceParseStrategy.fromJson(null),
        AiFinanceParseStrategy.defaults);
  });

  test('ai finance prompt follows custom parse strategy', () {
    final prompt = const AiFinancePromptBuilder().build(
      text: '昨天午饭18，从建行转100到微信',
      now: DateTime(2026, 6, 5, 8, 30),
      strategy: AiFinanceParseStrategy.defaults.copyWith(
        splitMultipleBills: false,
        mergeSameMerchant: false,
        detectTransfers: false,
        extractAccounts: false,
        extractTags: false,
        inferTime: false,
        requireLowConfidenceReview: false,
        noteLength: AiFinanceNoteLength.short,
      ),
    );

    expect(prompt, contains('note 必须≤10字'));
    expect(prompt, contains('不要主动拆分多笔账单'));
    expect(prompt, contains('不要把转账强制识别为 transfer'));
    expect(prompt, contains('完全没提时间或只有相对时间 → 使用当前时间'));
    expect(prompt, contains('不输出 account/from_account/to_account'));
    expect(prompt, contains('不输出 tag/tags'));
    expect(prompt, isNot(contains('账户列表：现金')));
  });

  test('ai finance image parsing sends multimodal glm request', () async {
    Map<String, dynamic>? capturedPayload;
    final client = AiFinanceClient(
      transport: ({
        required apiKey,
        required payload,
        required uri,
      }) async {
        capturedPayload = payload;
        return '''
{
  "choices": [
    {
      "message": {
        "content": "[{\\"amount\\":-38,\\"time\\":\\"2026-06-05T12:00:00\\",\\"note\\":\\"账单截图\\",\\"category\\":\\"三餐\\",\\"type\\":\\"expense\\"}]"
      }
    }
  ]
}
''';
      },
    );

    final bills = await client.parseImage(
      imageBytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/png',
      apiKey: 'glm-key',
      endpoint: '',
      model: '',
    );

    expect(capturedPayload?['model'], defaultGlmVisionModel);
    final messages = capturedPayload?['messages'] as List<dynamic>;
    final content = (messages.last as Map<String, dynamic>)['content'];
    expect(content, isA<List<dynamic>>());
    expect(content.toString(), contains('data:image/png;base64,AQID'));
    expect(bills.single.amount, -38);
    expect(bills.single.category, '三餐');
  });
}
