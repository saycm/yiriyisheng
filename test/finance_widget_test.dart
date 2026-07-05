// 中文注释：自动化测试文件，负责验证对应模块行为和回归场景。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  test('ai finance parser handles markdown json array', () {
    const parser = AiFinanceJsonParser();
    final bills = parser.parse('''
```json
[
  {"amount":-50,"time":"2026-06-05T12:00:00","note":"午饭","category":"三餐","type":"expense",},
  {"amount":3000,"time":"2026-06-05T09:00:00","note":"工资","category":"工资","type":"income"}
]
```
''');

    expect(bills, hasLength(2));
    expect(bills.first.amount, -50);
    expect(bills.first.category, '三餐');
    expect(bills.last.type, AiFinanceBillType.income);
  });

  test('ai finance parser keeps GoodNightLedger transfer details', () {
    const parser = AiFinanceJsonParser();
    final bills = parser.parse('''
AI 已识别：
{"amount":800,"category":"转账","type":"transfer","from_account":"建行","to_account":"微信零钱","tag":"自己","confidence":0.92,}
''');

    expect(bills, hasLength(1));
    expect(bills.single.type, AiFinanceBillType.transfer);
    expect(bills.single.fromAccount, '建行');
    expect(bills.single.toAccount, '微信零钱');
    expect(bills.single.tags, ['自己']);
    expect(bills.single.confidence, 0.92);
    expect(bills.single.time, isNotNull);
  });

  test('ai finance prompt carries GoodNightLedger extraction rules', () {
    final prompt = const AiFinancePromptBuilder().build(
      text: '从建行转800到零钱包，昨天午饭50',
      now: DateTime(2026, 6, 5, 8, 30),
    );

    expect(prompt, contains('始终返回 JSON 数组'));
    expect(prompt, contains('识别到多笔独立消费/收入/转账时'));
    expect(prompt, contains('拆开 AA'));
    expect(prompt, contains('同一商家的多件商品如果是一次性支付，合并为一笔'));
    expect(prompt, contains('from_account: 转出账户'));
    expect(prompt, contains('to_account: 转入账户'));
    expect(prompt, contains('账户列表：现金、支付宝、微信、银行卡、信用卡'));
  });

  test('ai finance transfer draft maps to expense from source account', () {
    final record = financeRecordFromAiBill(
      AiFinanceBillInfo(
        amount: 800,
        category: '转账',
        type: AiFinanceBillType.transfer,
        fromAccount: '建行',
        toAccount: '微信零钱',
        tags: const ['自己'],
        time: DateTime(2026, 6, 5, 9),
      ),
    );

    expect(record.type, '支出');
    expect(record.title, '转账');
    expect(record.account, '银行卡');
    expect(record.tags, ['自己']);
    expect(record.displayAmount, '-¥800.00');
  });

  test('ai finance client defaults to zhipu glm request', () async {
    Uri? capturedUri;
    Map<String, dynamic>? capturedPayload;
    String? capturedApiKey;
    final client = AiFinanceClient(
      transport: ({
        required apiKey,
        required payload,
        required uri,
      }) async {
        capturedUri = uri;
        capturedPayload = payload;
        capturedApiKey = apiKey;
        return '''
{
  "choices": [
    {
      "message": {
        "content": "[{\\"amount\\":-18,\\"time\\":\\"2026-06-05T12:00:00\\",\\"note\\":\\"午饭\\",\\"category\\":\\"三餐\\",\\"type\\":\\"expense\\"}]"
      }
    }
  ]
}
''';
      },
    );

    final bills = await client.parseText(
      text: '午饭18',
      apiKey: 'glm-key',
      endpoint: '',
      model: '',
    );

    expect(
      capturedUri.toString(),
      'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    );
    expect(capturedPayload?['model'], 'glm-4-flash');
    expect(capturedApiKey, 'glm-key');
    expect(bills.single.amount, -18);
    expect(bills.single.category, '三餐');
  });

  testWidgets('ai finance parse strategy can be edited from settings',
      (tester) async {
    final store = _MemoryLifeSummaryStore();
    await tester.pumpWidget(
      MaterialApp(home: LifeHomePage(appDataStore: store)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('module_sheet_finance')));
    await tester.pumpAndSettle();

    await openFinanceAiRecord(tester);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记账解析策略'));
    await tester.pumpAndSettle();

    expect(find.text('记账解析策略'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ai_parse_strategy_tags')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ai_parse_strategy_note_short')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('ai_parse_strategy_note_short')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ai_parse_strategy_save')),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai_parse_strategy_save')));
    await tester.pumpAndSettle();

    expect(store.savedStrategy?.extractTags, isFalse);
    expect(store.savedStrategy?.noteLength, AiFinanceNoteLength.short);

    await tester.tap(find.text('记账解析策略'));
    await tester.pumpAndSettle();
    final tagsSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('ai_parse_strategy_tags')).first,
    );
    expect(tagsSwitch.value, isFalse);
  });

  testWidgets('finance records filter income and expense', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final financeTile = find.byKey(const ValueKey('module_sheet_finance'));
    await tester.scrollUntilVisible(
      financeTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(financeTile);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('finance_bottom_nav_1')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.text('工资'),
      scrollable: find.byType(Scrollable).last,
      maxDrags: 8,
    );
    expect(find.text('工资'), findsOneWidget);
    expect(find.text('三餐'), findsOneWidget);

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('finance_filter_income')),
      scrollable: find.byType(Scrollable).last,
      up: false,
      maxDrags: 8,
    );
    await tester.tap(find.byKey(const ValueKey('finance_filter_income')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.text('工资'),
      scrollable: find.byType(Scrollable).last,
      maxDrags: 8,
    );
    expect(find.text('工资'), findsOneWidget);
    expect(find.text('三餐'), findsNothing);

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('finance_filter_expense')),
      scrollable: find.byType(Scrollable).last,
      up: false,
      maxDrags: 8,
    );
    await tester.tap(find.byKey(const ValueKey('finance_filter_expense')));
    await tester.pumpAndSettle();

    expect(find.text('工资'), findsNothing);
    await dragUntilFound(
      tester,
      find.text('三餐'),
      scrollable: find.byType(Scrollable).last,
      maxDrags: 8,
    );
    expect(find.text('三餐'), findsOneWidget);
  });

  testWidgets('finance records tab does not show duplicate entry cards',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_bottom_nav_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('finance_add_record')), findsNothing);
    expect(find.byKey(const ValueKey('finance_ai_record')), findsOneWidget);
    expect(find.text('记一笔'), findsOneWidget);
    expect(find.text('AI 记账'), findsOneWidget);
  });

  testWidgets('finance records can be added and edited', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_bottom_nav_1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('finance_category_income')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('finance_category_income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_category_奖金')));
    await tester.pumpAndSettle();
    expect(find.text('金额'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('finance_record_subtitle')),
      '项目奖励',
    );
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_8')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_8')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_8')));
    await tester.tap(find.byKey(const ValueKey('save_finance_record')));
    await tester.pumpAndSettle();

    expect(find.text('奖金'), findsOneWidget);
    expect(find.text('+¥888.00'), findsOneWidget);

    await tester.tap(find.text('奖金'));
    await tester.pumpAndSettle();
    expect(find.text('编辑记录'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('finance_record_subtitle')),
      '调整后的奖励',
    );
    await tester.tap(find.byKey(const ValueKey('finance_amount_clear')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_1')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_2')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_8')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_8')));
    await tester.tap(find.byKey(const ValueKey('save_finance_record')));
    await tester.pumpAndSettle();

    expect(find.text('调整后的奖励'), findsOneWidget);
    expect(find.text('+¥1,288.00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_bottom_nav_1')));
    await tester.pumpAndSettle();

    expect(find.text('奖金'), findsOneWidget);
    expect(find.text('调整后的奖励'), findsOneWidget);
    expect(find.text('+¥1,288.00'), findsOneWidget);
  });

  testWidgets('finance record sheet saves account and assets use real ledger',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_bottom_nav_1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('记一笔').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_category_交通')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_account_微信')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('finance_record_subtitle')),
      '地铁',
    );
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_1')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_2')));
    await tester.tap(find.byKey(const ValueKey('save_finance_record')));
    await tester.pumpAndSettle();

    expect(find.text('微信'), findsWidgets);
    expect(find.text('-¥12.00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('finance_bottom_nav_2')));
    await tester.pumpAndSettle();

    expect(find.text('账户余额'), findsOneWidget);
    final wechatAsset = find.byKey(const ValueKey('finance_asset_account_微信'));
    expect(wechatAsset, findsOneWidget);
    expect(find.descendant(of: wechatAsset, matching: find.text('微信')),
        findsOneWidget);
    expect(find.descendant(of: wechatAsset, matching: find.text('¥988.00')),
        findsOneWidget);
  });

  testWidgets('finance assets place negative sign after currency symbol',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_bottom_nav_2')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.text('信用卡'),
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('¥-48.00'), findsOneWidget);
    expect(find.text('--¥48.00'), findsNothing);
    expect(find.text('-¥48.00'), findsNothing);
  });

  testWidgets('finance ai accounting opens and requires api key',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();

    await openFinanceAiRecord(tester);

    expect(find.text('AI助手'), findsOneWidget);
    expect(find.text('未配置 AI 服务商，请先在设置中添加并绑定'), findsOneWidget);
    expect(find.text('暂无消息'), findsOneWidget);
    expect(find.text('去设置'), findsOneWidget);

    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();

    expect(find.text('AI小助手'), findsOneWidget);
    expect(find.text('服务商管理'), findsOneWidget);
    expect(find.text('能力绑定'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('ai_finance_input')),
      '昨天中午吃饭50，晚上奶茶12',
    );
    await tester.tap(find.byKey(const ValueKey('send_ai_finance_message')));
    await tester.pumpAndSettle();

    expect(find.text('请先填写 AI 接口 Key'), findsOneWidget);
  });

  testWidgets('finance ai sheet quick commands fill input', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await openFinanceAiRecord(tester);

    await tester.tap(find.byKey(const ValueKey('ai_assistant_quick_lunch')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ai_finance_input')))
          .controller
          ?.text,
      '今天中午午餐花了 28 元，用微信支付',
    );
  });

  testWidgets('finance ai exposes image capability and hides voice input',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await openFinanceAiRecord(tester);

    expect(find.byKey(const ValueKey('ai_finance_pick_image')), findsOneWidget);
    expect(find.byKey(const ValueKey('ai_finance_voice_input')), findsNothing);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    expect(find.text('图片理解'), findsOneWidget);
    expect(find.text('语音转文字'), findsNothing);
    expect(find.text('智谱GLM'), findsWidgets);
    expect(find.text('系统/云端语音识别'), findsNothing);
  });

  testWidgets('finance ai prompt editor saves custom prompt', (tester) async {
    final store = _MemoryLifeSummaryStore();
    await tester.pumpWidget(
      MaterialApp(home: LifeHomePage(appDataStore: store)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await openFinanceAiRecord(tester);

    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提示词编辑'));
    await tester.pumpAndSettle();

    expect(find.text('提示词编辑'), findsOneWidget);
    expect(find.text('{{OCR_TEXT}}'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('ai_prompt_editor_field')),
      '自定义平生提示词：{{OCR_TEXT}}',
    );
    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('ai_prompt_editor_save')),
      scrollable: find.byType(ListView).last,
    );
    await tester.tap(find.byKey(const ValueKey('ai_prompt_editor_save')));
    await tester.pumpAndSettle();

    expect(store.savedPrompt, '自定义平生提示词：{{OCR_TEXT}}');
    expect(find.text('提示词已保存'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提示词编辑'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('ai_prompt_editor_field')),
          )
          .controller
          ?.text,
      '自定义平生提示词：{{OCR_TEXT}}',
    );
  });

  testWidgets('finance ai scales selected bill images before upload',
      (tester) async {
    const channel = MethodChannel('plugins.flutter.io/image_picker');
    Map<dynamic, dynamic>? capturedArgs;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'pickImage') {
        capturedArgs = call.arguments as Map<dynamic, dynamic>;
      }
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(
      MaterialApp(home: LifeHomePage(appDataStore: _MemoryLifeSummaryStore())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await openFinanceAiRecord(tester);

    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('服务商管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('智谱GLM'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('ai_provider_api_key')),
      'glm-key',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ai_finance_pick_image')));
    await tester.pumpAndSettle();

    expect(capturedArgs?['maxWidth'], 1600.0);
    expect(capturedArgs?['maxHeight'], 1600.0);
    expect(capturedArgs?['imageQuality'], 80);
  });

  testWidgets('finance glm ai config survives module switches', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await openFinanceAiRecord(tester);

    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('服务商管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('智谱GLM'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('ai_provider_api_key')), 'persisted-glm-key');
    await tester.enterText(
        find.byKey(const ValueKey('ai_provider_text_model')), 'glm-4.6');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('ai_finance_input')),
      '午饭18',
    );
    await tester.tap(find.byKey(const ValueKey('send_ai_finance_message')));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await openFinanceAiRecord(tester);
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('服务商管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('智谱GLM'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
              find.byKey(const ValueKey('ai_provider_text_model')))
          .controller
          ?.text,
      'glm-4.6',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ai_provider_api_key')))
          .controller
          ?.text,
      'persisted-glm-key',
    );
  });

  testWidgets('finance ai settings refreshes after provider save',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await openFinanceAiRecord(tester);

    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();
    expect(find.text('智谱GLM未配置'), findsOneWidget);

    await tester.tap(find.text('服务商管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('智谱GLM'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('ai_provider_api_key')),
      'fresh-glm-key',
    );
    await tester.enterText(
      find.byKey(const ValueKey('ai_provider_text_model')),
      'glm-4.6',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('智谱GLM已配置'), findsOneWidget);

    await tester.tap(find.text('服务商管理'));
    await tester.pumpAndSettle();
    expect(find.text('文本模型 glm-4.6'), findsOneWidget);
    await tester.tap(find.text('智谱GLM'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
              find.byKey(const ValueKey('ai_provider_text_model')))
          .controller
          ?.text,
      'glm-4.6',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ai_provider_api_key')))
          .controller
          ?.text,
      'fresh-glm-key',
    );
  });

  testWidgets('finance overview opens assets and switches trend range',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final financeTile = find.byKey(const ValueKey('module_sheet_finance'));
    await tester.scrollUntilVisible(
      financeTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(financeTile);
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.text('查看资产详情'),
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('查看资产详情'));
    await tester.pumpAndSettle();

    expect(find.text('资产占比'), findsOneWidget);
    expect(find.text('银行卡'), findsOneWidget);
    expect(find.text('招商储蓄卡'), findsOneWidget);

    await tester.tap(find.text('总览').last);
    await tester.pumpAndSettle();

    await expectFinanceOverviewDoesNotContain(
      tester,
      const [
        '本月管控',
        '本月预算',
        '全部账户',
        '财务联动',
        '本月收入',
        '本月支出',
        '净现金流',
        '本月待复核/总数',
        '支出分类',
        '最近记录',
      ],
    );

    await tester.scrollUntilVisible(
      find.text('7天支出 ¥44'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('7天支出 ¥44'), findsOneWidget);

    await tester.ensureVisible(find.text('6个月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6个月'));
    await tester.pumpAndSettle();
    expect(find.text('6个月支出 ¥2652'), findsOneWidget);

    await tester.tap(find.text('收入'));
    await tester.pumpAndSettle();
    expect(find.text('6个月收入 ¥18000'), findsOneWidget);
  });

  testWidgets('finance overview shows budgets fixed costs and alerts',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.text('分类预算'),
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('三餐'), findsWidgets);
    expect(find.text('已用 ¥18.00 / ¥1,000.00'), findsOneWidget);
    expect(find.text('数码分期'), findsWidgets);
    expect(find.text('已用 ¥500.00 / ¥600.00'), findsOneWidget);

    await dragUntilFound(
      tester,
      find.text('固定支出'),
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('手机分期还款'), findsOneWidget);
    expect(find.text('每月预计 ¥500.00'), findsOneWidget);

    await dragUntilFound(
      tester,
      find.text('异常提醒'),
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('数码分期接近分类预算'), findsOneWidget);
    expect(find.textContaining('已使用 83%'), findsOneWidget);
  });

  testWidgets('finance overview places property health below assets workbench',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();

    final assetsTitle = find.text('资产工作台');
    final healthTitle = find.text('财产健康值');

    expect(assetsTitle, findsOneWidget);
    expect(healthTitle, findsOneWidget);
    expect(
      tester.getTopLeft(assetsTitle).dy,
      lessThan(tester.getTopLeft(healthTitle).dy),
    );
  });

  testWidgets('finance overview opens property health detail', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.text('财产健康值'),
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('财产健康值'), findsOneWidget);
    expect(find.textContaining('分 ·'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('finance_health_card')));
    await tester.pumpAndSettle();

    expect(find.text('健康值拆解'), findsOneWidget);
    expect(find.text('现金流能力'), findsWidgets);
    expect(find.text('应急能力'), findsWidgets);
    expect(find.text('预算纪律'), findsWidgets);
    expect(find.text('固定支出压力'), findsOneWidget);
    expect(find.text('消费结构'), findsOneWidget);
  });

  testWidgets('finance page tolerates rapid scroll gestures', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();

    for (final tab in [0, 1, 2]) {
      await tester.tap(find.byKey(ValueKey('finance_bottom_nav_$tab')));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).last;
      for (var index = 0; index < 6; index++) {
        await tester.fling(scrollable, const Offset(0, -900), 4800);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.fling(scrollable, const Offset(0, 900), 4800);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

class _MemoryLifeSummaryStore implements LifeSummaryStore {
  AiFinanceParseStrategy? savedStrategy;
  String? savedPrompt;

  @override
  Future<LifeSummarySnapshot?> load() async => null;

  @override
  Future<void> save({
    required int foodCalories,
    required Map<String, int> workoutGroupsByAction,
    required List<TodoItem> todos,
    required List<FinanceRecord> financeRecords,
    required List<WorkoutPlan> workoutPlans,
    required ActiveWorkoutSession? activeWorkoutSession,
    required List<WorkoutHistoryEntry> workoutHistory,
    required String aiFinanceEndpoint,
    required String aiFinanceModel,
    required String aiFinanceApiKey,
    required AiFinanceParseStrategy aiFinanceParseStrategy,
    required String aiFinanceCustomPrompt,
  }) async {
    savedStrategy = aiFinanceParseStrategy;
    savedPrompt = aiFinanceCustomPrompt;
  }
}

Future<void> expectFinanceOverviewDoesNotContain(
  WidgetTester tester,
  List<String> labels,
) async {
  final scrollable = find.byType(Scrollable).last;
  for (var step = 0; step < 8; step++) {
    for (final label in labels) {
      expect(find.text(label), findsNothing);
    }
    await tester.drag(scrollable, const Offset(0, -320));
    await tester.pumpAndSettle();
  }
  for (final label in labels) {
    expect(find.text(label), findsNothing);
  }
}
