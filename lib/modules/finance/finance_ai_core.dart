// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const String defaultGlmChatEndpoint =
    'https://open.bigmodel.cn/api/paas/v4/chat/completions';
const String defaultGlmTextModel = 'glm-4-flash';
const String defaultGlmVisionModel = 'glm-4.6v';

enum AiFinanceBillType { income, expense, transfer }

enum AiFinanceNoteLength {
  short(10, '简短 ≤10字'),
  standard(15, '标准 ≤15字'),
  detailed(24, '详细 ≤24字');

  const AiFinanceNoteLength(this.limit, this.label);

  final int limit;
  final String label;
}

class AiFinanceParseStrategy {
  // 解析策略是用户可调的“提示词开关”，最终会参与构建 AI 请求提示。
  const AiFinanceParseStrategy({
    this.splitMultipleBills = true,
    this.mergeSameMerchant = true,
    this.detectTransfers = true,
    this.extractAccounts = true,
    this.extractTags = true,
    this.inferTime = true,
    this.requireLowConfidenceReview = true,
    this.noteLength = AiFinanceNoteLength.standard,
  });

  static const defaults = AiFinanceParseStrategy();

  final bool splitMultipleBills;
  final bool mergeSameMerchant;
  final bool detectTransfers;
  final bool extractAccounts;
  final bool extractTags;
  final bool inferTime;
  final bool requireLowConfidenceReview;
  final AiFinanceNoteLength noteLength;

  AiFinanceParseStrategy copyWith({
    bool? splitMultipleBills,
    bool? mergeSameMerchant,
    bool? detectTransfers,
    bool? extractAccounts,
    bool? extractTags,
    bool? inferTime,
    bool? requireLowConfidenceReview,
    AiFinanceNoteLength? noteLength,
  }) {
    return AiFinanceParseStrategy(
      splitMultipleBills: splitMultipleBills ?? this.splitMultipleBills,
      mergeSameMerchant: mergeSameMerchant ?? this.mergeSameMerchant,
      detectTransfers: detectTransfers ?? this.detectTransfers,
      extractAccounts: extractAccounts ?? this.extractAccounts,
      extractTags: extractTags ?? this.extractTags,
      inferTime: inferTime ?? this.inferTime,
      requireLowConfidenceReview:
          requireLowConfidenceReview ?? this.requireLowConfidenceReview,
      noteLength: noteLength ?? this.noteLength,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'splitMultipleBills': splitMultipleBills,
      'mergeSameMerchant': mergeSameMerchant,
      'detectTransfers': detectTransfers,
      'extractAccounts': extractAccounts,
      'extractTags': extractTags,
      'inferTime': inferTime,
      'requireLowConfidenceReview': requireLowConfidenceReview,
      'noteLength': noteLength.name,
    };
  }

  static AiFinanceParseStrategy fromJson(Object? value) {
    if (value is! Map) {
      return defaults;
    }
    return AiFinanceParseStrategy(
      splitMultipleBills:
          _readBool(value, 'splitMultipleBills', defaults.splitMultipleBills),
      mergeSameMerchant:
          _readBool(value, 'mergeSameMerchant', defaults.mergeSameMerchant),
      detectTransfers:
          _readBool(value, 'detectTransfers', defaults.detectTransfers),
      extractAccounts:
          _readBool(value, 'extractAccounts', defaults.extractAccounts),
      extractTags: _readBool(value, 'extractTags', defaults.extractTags),
      inferTime: _readBool(value, 'inferTime', defaults.inferTime),
      requireLowConfidenceReview: _readBool(
        value,
        'requireLowConfidenceReview',
        defaults.requireLowConfidenceReview,
      ),
      noteLength: AiFinanceNoteLength.values.firstWhere(
        (item) => item.name == value['noteLength'],
        orElse: () => defaults.noteLength,
      ),
    );
  }

  static bool _readBool(Map<dynamic, dynamic> json, String key, bool fallback) {
    final value = json[key];
    return value is bool ? value : fallback;
  }

  @override
  bool operator ==(Object other) {
    return other is AiFinanceParseStrategy &&
        other.splitMultipleBills == splitMultipleBills &&
        other.mergeSameMerchant == mergeSameMerchant &&
        other.detectTransfers == detectTransfers &&
        other.extractAccounts == extractAccounts &&
        other.extractTags == extractTags &&
        other.inferTime == inferTime &&
        other.requireLowConfidenceReview == requireLowConfidenceReview &&
        other.noteLength == noteLength;
  }

  @override
  int get hashCode => Object.hash(
        splitMultipleBills,
        mergeSameMerchant,
        detectTransfers,
        extractAccounts,
        extractTags,
        inferTime,
        requireLowConfidenceReview,
        noteLength,
      );
}

class AiFinanceBillInfo {
  const AiFinanceBillInfo({
    this.amount,
    this.time,
    this.note,
    this.category,
    this.type,
    this.account,
    this.fromAccount,
    this.toAccount,
    this.tags,
    this.confidence = 0.0,
  });

  final double? amount;
  final DateTime? time;
  final String? note;
  final String? category;
  final AiFinanceBillType? type;
  final String? account;
  final String? fromAccount;
  final String? toAccount;
  final List<String>? tags;
  final double confidence;

  AiFinanceBillInfo copyWith({
    double? amount,
    DateTime? time,
    String? note,
    String? category,
    AiFinanceBillType? type,
    String? account,
    String? fromAccount,
    String? toAccount,
    List<String>? tags,
    double? confidence,
  }) {
    return AiFinanceBillInfo(
      amount: amount ?? this.amount,
      time: time ?? this.time,
      note: note ?? this.note,
      category: category ?? this.category,
      type: type ?? this.type,
      account: account ?? this.account,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
      tags: tags ?? this.tags,
      confidence: confidence ?? this.confidence,
    );
  }

  factory AiFinanceBillInfo.fromJson(Map<String, dynamic> json) {
    return AiFinanceBillInfo(
      amount: (json['amount'] as num?)?.toDouble(),
      time: _parseAiFinanceTime(json['time']),
      note: json['note'] as String? ?? json['merchant'] as String?,
      category: json['category'] as String?,
      type: _parseAiFinanceBillType(json['type']),
      account: json['account'] as String?,
      fromAccount:
          json['from_account'] as String? ?? json['fromAccount'] as String?,
      toAccount: json['to_account'] as String? ?? json['toAccount'] as String?,
      tags: _parseAiFinanceTags(json['tags'] ?? json['tag']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'amount': amount,
      'time': time?.toIso8601String(),
      'note': note,
      'category': category,
      'type': type?.name,
      'account': account,
      'from_account': fromAccount,
      'to_account': toAccount,
      'tags': tags,
      'confidence': confidence,
    };
  }

  static DateTime? _parseAiFinanceTime(dynamic value) {
    if (value is! String) {
      return null;
    }
    final raw = value.trim();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw) ??
        DateTime.tryParse(raw.replaceAll(RegExp(r'\s+'), ''));
  }

  static AiFinanceBillType? _parseAiFinanceBillType(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().toLowerCase();
    if (text.contains('income') || text == '收入') {
      return AiFinanceBillType.income;
    }
    if (text.contains('transfer') || text == '转账' || text == '轉帳') {
      return AiFinanceBillType.transfer;
    }
    if (text.contains('expense') || text == '支出') {
      return AiFinanceBillType.expense;
    }
    return null;
  }

  static List<String>? _parseAiFinanceTags(dynamic value) {
    if (value == null) {
      return null;
    }
    final tags = <String>[];
    if (value is String) {
      tags.addAll(
        value
            .split(RegExp(r'[,\n，、;；|]+'))
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty),
      );
    } else if (value is List) {
      tags.addAll(
        value
            .map((tag) => tag.toString().trim())
            .where((tag) => tag.isNotEmpty),
      );
    }
    return tags.isEmpty ? null : tags;
  }
}

class AiFinanceJsonParser {
  // AI 返回可能包含 markdown 代码块或说明文字，这里负责提取可靠 JSON 片段。
  const AiFinanceJsonParser();

  List<AiFinanceBillInfo> parse(String response) {
    // 这部分沿用晚安记账的核心策略：优先找 JSON 数组，失败再找单个对象。
    final arrayBlock = _extractBalancedBlock(response, '[', ']');
    if (arrayBlock != null) {
      try {
        final decoded = jsonDecode(_cleanupJson(arrayBlock));
        if (decoded is List) {
          final bills = <AiFinanceBillInfo>[];
          for (final item in decoded) {
            final map = _asStringMap(item);
            if (map == null) {
              continue;
            }
            final bill = _sanitize(AiFinanceBillInfo.fromJson(map));
            if (bill != null) {
              bills.add(bill);
            }
          }
          if (bills.isNotEmpty) {
            return bills;
          }
        }
      } catch (_) {
        // AI 可能包 Markdown 或生成 JSON5 风格，继续走单对象兜底。
      }
    }

    final objectBlock = _extractBalancedBlock(response, '{', '}');
    if (objectBlock == null) {
      return const [];
    }
    try {
      final map = _asStringMap(jsonDecode(_cleanupJson(objectBlock)));
      if (map == null) {
        return const [];
      }
      final bill = _sanitize(AiFinanceBillInfo.fromJson(map));
      return bill == null ? const [] : [bill];
    } catch (_) {
      return const [];
    }
  }

  AiFinanceBillInfo? _sanitize(AiFinanceBillInfo bill) {
    final amount = bill.amount;
    if (amount == null || amount.abs() <= 0) {
      return null;
    }
    return bill.time == null ? bill.copyWith(time: DateTime.now()) : bill;
  }

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  String _cleanupJson(String input) {
    final out = StringBuffer();
    var inString = false;
    var escaped = false;
    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (inString) {
        out.write(char);
        if (escaped) {
          escaped = false;
        } else if (char == '\\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }
      if (char == '"') {
        inString = true;
        out.write(char);
        continue;
      }
      if (char == ',') {
        var next = index + 1;
        while (next < input.length && input[next].trim().isEmpty) {
          next++;
        }
        if (next < input.length && (input[next] == '}' || input[next] == ']')) {
          continue;
        }
      }
      out.write(char);
    }
    return out.toString();
  }

  String? _extractBalancedBlock(String text, String open, String close) {
    final start = text.indexOf(open);
    if (start < 0) {
      return null;
    }
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var index = start; index < text.length; index++) {
      final char = text[index];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == '\\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (inString) {
        continue;
      }
      if (char == open) {
        depth++;
      } else if (char == close) {
        depth--;
        if (depth == 0) {
          return text.substring(start, index + 1);
        }
      }
    }
    return null;
  }
}

class AiFinancePromptBuilder {
  const AiFinancePromptBuilder();

  static const defaultTemplate = '''{{INPUT_SOURCE}}提取记账信息，返回JSON数组。

当前时间：{{CURRENT_TIME}}

{{OCR_TEXT}}

{{CATEGORIES}}{{ACCOUNTS}}

输出格式：
- 始终返回 JSON 数组，即使只有一笔，也包成 [{...}]
- 识别到多笔独立消费/收入/转账时，数组中每笔一个对象，按时间先后顺序排列
- “拆开 AA”“拆开报销”“拼单”等场景，每个独立支付/收款都算一笔
- 同一商家的多件商品如果是一次性支付，合并为一笔

字段说明：
1. amount: 金额（支出负数，收入正数，转账正数）
2. time: ISO8601格式，尽量推断时间
3. note: 备注（必须≤15字，超过则精简），优先商户/商品/用途
4. category: 从分类列表选择（转账填“转账”）
5. type: income、expense 或 transfer
6. account: 支付账户（收入/支出可用）
7. from_account: 转出账户（仅转账可用）
8. to_account: 转入账户（仅转账可用）
9. tag/tags: 标签（可选，单个字符串或字符串数组）

注意：只返回 JSON 数组，尽量推断时间不要返回 null。''';

  static const _expenseCategories = [
    '三餐',
    '餐饮',
    '咖啡',
    '奶茶',
    '交通',
    '购物',
    '数码分期',
    '娱乐',
    '居家',
    '通讯',
    '水电',
    '医疗',
    '教育',
  ];

  static const _incomeCategories = [
    '工资',
    '理财收益',
    '奖金',
    '报销',
    '红包',
    '兼职',
  ];

  String build({
    required String text,
    DateTime? now,
    AiFinanceParseStrategy strategy = AiFinanceParseStrategy.defaults,
    String customPrompt = '',
    String inputSource = '从以下自然语言中',
  }) {
    final ts = now ?? DateTime.now();
    final currentDate = '${ts.year}-${_pad(ts.month)}-${_pad(ts.day)}';
    final currentTime = '$currentDate ${_pad(ts.hour)}:${_pad(ts.minute)}';
    final accountList =
        strategy.extractAccounts ? '\n账户列表：现金、支付宝、微信、银行卡、信用卡' : '';
    final customTemplate = customPrompt.trim();
    if (customTemplate.isNotEmpty) {
      return _renderCustomTemplate(
        customTemplate,
        inputSource: inputSource,
        currentDate: currentDate,
        currentTime: currentTime,
        text: text,
        categories: '分类列表：\n'
            '支出：${_expenseCategories.join('、')}\n'
            '收入：${_incomeCategories.join('、')}',
        accounts: accountList,
      );
    }
    final splitRule = strategy.splitMultipleBills
        ? '- 识别到多笔独立消费/收入/转账时，数组中每笔一个对象，按时间先后顺序排列'
        : '- 不要主动拆分多笔账单；除非用户明确要求“拆开/分别记/每笔一条”，否则合并为一笔摘要记录';
    final mergeRule = strategy.mergeSameMerchant
        ? '- 同一商家的多件商品如果是一次性支付，合并为一笔'
        : '- 同一商家的多件商品也按用户描述分别保留，不主动合并';
    final transferTypeRule = strategy.detectTransfers
        ? 'income、expense 或 transfer'
        : 'income 或 expense；不要把转账强制识别为 transfer';
    final timeRule = strategy.inferTime
        ? '''2. time: ISO8601格式，尽量推断时间：
   - 明确时间（如“14:30”“2026-06-05”）→ 直接使用
   - 相对日期（昨天、前天、上周）→ 推算具体日期
   - 时间段（早上、中午、晚上）→ 使用合理时刻（早上09:00、中午12:00、晚上19:00）
   - 完全没提时间 → 使用当前时间'''
        : '''2. time: ISO8601格式：
   - 明确时间（如“14:30”“2026-06-05”）→ 直接使用
   - 完全没提时间或只有相对时间 → 使用当前时间，不推断昨天/前天/上周/时间段''';
    final accountFields = strategy.extractAccounts
        ? '''6. account: 支付账户（收入/支出可用）
7. from_account: 转出账户（仅转账可用）
8. to_account: 转入账户（仅转账可用）'''
        : '6. 不输出 account/from_account/to_account';
    final tagField = strategy.extractTags
        ? '9. tag/tags: 标签（可选，单个字符串或字符串数组）'
        : '9. 不输出 tag/tags';
    final confidenceField = strategy.requireLowConfidenceReview
        ? '10. confidence: 0-1 的置信度，低于0.7代表需要用户复核'
        : '10. confidence: 可省略';
    final transferExample = strategy.detectTransfers && strategy.extractAccounts
        ? '\n"从建行转800到零钱包" → [{"amount":800,"time":"${currentDate}T09:00:00","category":"转账","type":"transfer","from_account":"银行卡","to_account":"微信","tag":"自己"}]'
        : '';
    final noteLimit = strategy.noteLength.limit;
    return '''从以下自然语言中提取记账信息，返回JSON数组。

当前时间：$currentTime

用户输入：
$text

分类列表：
支出：${_expenseCategories.join('、')}
收入：${_incomeCategories.join('、')}$accountList

输出要求：
- 始终返回 JSON 数组，即使只有一笔，也包成 [{...}]
- 只返回 JSON 数组，不要解释
$splitRule
- “拆开 AA”“拆开报销”“拼单”等场景，每个独立支付/收款都算一笔
$mergeRule

字段说明：
1. amount: 金额（支出负数，收入正数，转账正数）
$timeRule
3. note: 备注（必须≤$noteLimit字，超过则精简），优先商户/商品/用途
4. category: 从分类列表选择（转账填“转账”）
5. type: $transferTypeRule
$accountFields
$tagField
$confidenceField

示例：
"昨天中午吃饭50，晚上奶茶12" → [{"amount":-50,"time":"${currentDate}T12:00:00","note":"吃饭","category":"三餐","type":"expense"},{"amount":-12,"time":"${currentDate}T19:00:00","note":"奶茶","category":"咖啡","type":"expense"}]
"工资到账3000" → [{"amount":3000,"time":"${currentDate}T09:00:00","note":"工资到账","category":"工资","type":"income"}]
$transferExample

注意：只返回 JSON 数组，note 必须≤$noteLimit字。''';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  String _renderCustomTemplate(
    String template, {
    required String inputSource,
    required String currentDate,
    required String currentTime,
    required String text,
    required String categories,
    required String accounts,
  }) {
    final rendered = template
        .replaceAll('{{INPUT_SOURCE}}', inputSource)
        .replaceAll('{{CURRENT_TIME}}', currentTime)
        .replaceAll('{{CURRENT_DATE}}', currentDate)
        .replaceAll('{{OCR_TEXT}}', text)
        .replaceAll('{{CATEGORIES}}', categories)
        .replaceAll('{{ACCOUNTS}}', accounts);
    if (template.contains('{{OCR_TEXT}}')) {
      return rendered;
    }
    return '$rendered\n\n用户输入：\n$text';
  }
}

class AiFinanceException implements Exception {
  const AiFinanceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiFinanceImageInput {
  const AiFinanceImageInput({
    required this.bytes,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String mimeType;
}

typedef AiFinanceTransport = Future<String> Function({
  required Uri uri,
  required String apiKey,
  required Map<String, Object?> payload,
});

class AiFinanceClient {
  AiFinanceClient({
    this.parser = const AiFinanceJsonParser(),
    this.promptBuilder = const AiFinancePromptBuilder(),
    AiFinanceTransport? transport,
  }) : _transport = transport ?? _defaultTransport;

  final AiFinanceJsonParser parser;
  final AiFinancePromptBuilder promptBuilder;
  final AiFinanceTransport _transport;

  Future<List<AiFinanceBillInfo>> parseText({
    required String text,
    required String apiKey,
    required String endpoint,
    required String model,
    AiFinanceParseStrategy strategy = AiFinanceParseStrategy.defaults,
    String customPrompt = '',
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw const AiFinanceException('请先输入要记账的内容');
    }
    if (apiKey.trim().isEmpty) {
      throw const AiFinanceException('请先填写 AI 接口 Key');
    }

    final uri = _resolveEndpoint(endpoint);
    try {
      final body = await _transport(
        uri: uri,
        apiKey: apiKey,
        payload: {
          'model': model.trim().isEmpty ? defaultGlmTextModel : model.trim(),
          'temperature': 0.1,
          'messages': [
            {
              'role': 'system',
              'content': '你是严谨的记账信息提取器，只输出 JSON 数组。',
            },
            {
              'role': 'user',
              'content': promptBuilder.build(
                text: trimmedText,
                strategy: strategy,
                customPrompt: customPrompt,
              ),
            },
          ],
        },
      );
      final content = _extractChatContent(body);
      final bills = parser.parse(content);
      if (bills.isEmpty) {
        throw const AiFinanceException('AI 没有返回可用账单，请换一种说法再试');
      }
      return bills;
    } on AiFinanceException {
      rethrow;
    } catch (error) {
      throw AiFinanceException('AI 记账失败：$error');
    }
  }

  Future<List<AiFinanceBillInfo>> parseImage({
    required Uint8List imageBytes,
    required String mimeType,
    required String apiKey,
    required String endpoint,
    required String model,
    AiFinanceParseStrategy strategy = AiFinanceParseStrategy.defaults,
    String customPrompt = '',
  }) async {
    return parseImages(
      images: [
        AiFinanceImageInput(bytes: imageBytes, mimeType: mimeType),
      ],
      apiKey: apiKey,
      endpoint: endpoint,
      model: model,
      strategy: strategy,
      customPrompt: customPrompt,
    );
  }

  Future<List<AiFinanceBillInfo>> parseImages({
    required List<AiFinanceImageInput> images,
    required String apiKey,
    required String endpoint,
    required String model,
    AiFinanceParseStrategy strategy = AiFinanceParseStrategy.defaults,
    String customPrompt = '',
  }) async {
    final validImages =
        images.where((image) => image.bytes.isNotEmpty).toList(growable: false);
    if (validImages.isEmpty) {
      throw const AiFinanceException('请选择要识别的账单图片');
    }
    if (apiKey.trim().isEmpty) {
      throw const AiFinanceException('请先填写 AI 接口 Key');
    }

    final uri = _resolveEndpoint(endpoint);
    try {
      final contentParts = <Map<String, Object?>>[
        {
          'type': 'text',
          'text': promptBuilder.build(
            text: '请识别图片中的账单、付款截图、订单或收据，提取金额、时间、商家、分类、账户和备注。',
            strategy: strategy,
            customPrompt: customPrompt,
            inputSource: '从以下账单图片中',
          ),
        },
        for (final image in validImages)
          {
            'type': 'image_url',
            'image_url': {
              'url':
                  'data:${image.mimeType};base64,${base64Encode(image.bytes)}',
            },
          },
      ];
      final body = await _transport(
        uri: uri,
        apiKey: apiKey,
        payload: {
          'model': model.trim().isEmpty ? defaultGlmVisionModel : model.trim(),
          'temperature': 0.1,
          'messages': [
            {
              'role': 'system',
              'content': '你是严谨的账单图片识别器，只输出 JSON 数组。',
            },
            {
              'role': 'user',
              'content': contentParts,
            },
          ],
        },
      );
      final content = _extractChatContent(body);
      final bills = parser.parse(content);
      if (bills.isEmpty) {
        throw const AiFinanceException('AI 没有从图片中识别到账单，请换一张图片再试');
      }
      return bills;
    } on AiFinanceException catch (error) {
      throw _mapImageApiException(error);
    } catch (error) {
      throw _mapImageUnexpectedException(error);
    }
  }

  static Future<String> _defaultTransport({
    required Uri uri,
    required String apiKey,
    required Map<String, Object?> payload,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiFinanceException('AI 接口请求失败：${response.statusCode} $body');
      }
      return body;
    } finally {
      client.close(force: true);
    }
  }

  Uri _resolveEndpoint(String endpoint) {
    final raw =
        endpoint.trim().isEmpty ? defaultGlmChatEndpoint : endpoint.trim();
    final uri = Uri.parse(raw);
    if (uri.path.isEmpty || uri.path == '/') {
      return uri.replace(path: '/v1/chat/completions');
    }
    if (uri.path.endsWith('/v1')) {
      return uri.replace(path: '${uri.path}/chat/completions');
    }
    if (uri.path.endsWith('/v1/')) {
      return uri.replace(path: '${uri.path}chat/completions');
    }
    return uri;
  }

  String _extractChatContent(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AiFinanceException('AI 接口返回格式不是 JSON 对象');
    }
    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic> && message['content'] is String) {
          return message['content'] as String;
        }
        if (first['text'] is String) {
          return first['text'] as String;
        }
      }
    }
    throw const AiFinanceException('AI 接口返回中没有 message.content');
  }

  AiFinanceException _mapImageApiException(AiFinanceException error) {
    if (error.message.startsWith('AI 接口请求失败：')) {
      return const AiFinanceException(
        '图片理解接口返回异常。请检查 API Key、账号额度或视觉模型是否可用后再试。',
      );
    }
    return error;
  }

  AiFinanceException _mapImageUnexpectedException(Object error) {
    if (_isNetworkTransportError(error)) {
      return const AiFinanceException(
        '图片理解连接失败。请检查网络连接，或稍后换一张较清晰的截图再试。',
      );
    }
    return const AiFinanceException('图片理解失败。请稍后重试，或换一张更清晰的账单图片。');
  }

  bool _isNetworkTransportError(Object error) {
    final text = error.toString().toLowerCase();
    return error is SocketException ||
        error is HttpException ||
        error is HandshakeException ||
        text.contains('connection reset') ||
        text.contains('connection closed') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection timed out') ||
        text.contains('connection refused');
  }
}
