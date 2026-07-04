// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

class _FinanceAiSettingsPage extends StatefulWidget {
  const _FinanceAiSettingsPage({
    required this.endpoint,
    required this.model,
    required this.apiKey,
    required this.parseStrategy,
    required this.customPrompt,
    required this.onConfigChanged,
  });

  final String endpoint;
  final String model;
  final String apiKey;
  final AiFinanceParseStrategy parseStrategy;
  final String customPrompt;
  final void Function({
    required String endpoint,
    required String model,
    required String apiKey,
    AiFinanceParseStrategy? parseStrategy,
    String? customPrompt,
  }) onConfigChanged;

  @override
  State<_FinanceAiSettingsPage> createState() => _FinanceAiSettingsPageState();
}

class _FinanceAiSettingsPageState extends State<_FinanceAiSettingsPage> {
  bool _enabled = true;
  late String _endpoint;
  late String _model;
  late String _apiKey;
  late AiFinanceParseStrategy _parseStrategy;
  late String _customPrompt;

  @override
  void initState() {
    super.initState();
    _endpoint = widget.endpoint;
    _model = widget.model;
    _apiKey = widget.apiKey;
    _parseStrategy = widget.parseStrategy;
    _customPrompt = widget.customPrompt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FinanceAiPageHeader(
              title: 'AI小助手',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    decoration: _financeAiCardDecoration(),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '启用AI小助手',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                '用于文字记账、识别建议和后续扩展能力。',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _enabled,
                          onChanged: (value) {
                            setState(() => _enabled = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FinanceAiSettingsTile(
                    icon: Icons.hub_rounded,
                    title: '服务商管理',
                    subtitle: _providerSubtitle(_apiKey),
                    onTap: _openProviderManage,
                  ),
                  const SizedBox(height: 16),
                  const ModuleSectionTitle(
                    icon: Icons.link_rounded,
                    title: '能力绑定',
                  ),
                  const SizedBox(height: 10),
                  const _FinanceAiCapabilityTile(
                    icon: Icons.chat_bubble_rounded,
                    title: '文本对话',
                    subtitle: '智谱GLM',
                    active: true,
                  ),
                  const _FinanceAiCapabilityTile(
                    icon: Icons.image_search_rounded,
                    title: '图片理解',
                    subtitle: '智谱GLM',
                    active: true,
                  ),
                  const SizedBox(height: 16),
                  const ModuleSectionTitle(
                    icon: Icons.tune_rounded,
                    title: '高级设置',
                  ),
                  const SizedBox(height: 10),
                  _FinanceAiSettingsTile(
                    icon: Icons.receipt_long_rounded,
                    title: '记账解析策略',
                    subtitle: _strategySubtitle(_parseStrategy),
                    onTap: _openParseStrategy,
                  ),
                  const SizedBox(height: 10),
                  _FinanceAiSettingsTile(
                    icon: Icons.edit_note_rounded,
                    title: '提示词编辑',
                    subtitle: _promptSubtitle(_customPrompt),
                    onTap: _openPromptEditor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProviderManage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _FinanceAiProviderManagePage(
          endpoint: _endpoint,
          model: _model,
          apiKey: _apiKey,
          onConfigChanged: _updateConfig,
        ),
      ),
    );
  }

  void _openParseStrategy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _FinanceAiParseStrategyPage(
          strategy: _parseStrategy,
          onChanged: _updateParseStrategy,
        ),
      ),
    );
  }

  void _openPromptEditor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _FinanceAiPromptEditPage(
          prompt: _customPrompt,
          onChanged: _updateCustomPrompt,
        ),
      ),
    );
  }

  void _updateConfig({
    required String endpoint,
    required String model,
    required String apiKey,
    AiFinanceParseStrategy? parseStrategy,
    String? customPrompt,
  }) {
    final nextEndpoint =
        endpoint.trim().isEmpty ? defaultGlmChatEndpoint : endpoint.trim();
    final nextModel = model.trim().isEmpty ? defaultGlmTextModel : model.trim();
    final nextApiKey = apiKey.trim();
    final nextParseStrategy = parseStrategy ?? _parseStrategy;
    final nextCustomPrompt = customPrompt ?? _customPrompt;
    setState(() {
      _endpoint = nextEndpoint;
      _model = nextModel;
      _apiKey = nextApiKey;
      _parseStrategy = nextParseStrategy;
      _customPrompt = nextCustomPrompt;
    });
    widget.onConfigChanged(
      endpoint: nextEndpoint,
      model: nextModel,
      apiKey: nextApiKey,
      parseStrategy: nextParseStrategy,
      customPrompt: nextCustomPrompt,
    );
  }

  void _updateParseStrategy(AiFinanceParseStrategy strategy) {
    _updateConfig(
      endpoint: _endpoint,
      model: _model,
      apiKey: _apiKey,
      parseStrategy: strategy,
    );
  }

  void _updateCustomPrompt(String prompt) {
    _updateConfig(
      endpoint: _endpoint,
      model: _model,
      apiKey: _apiKey,
      customPrompt: prompt,
    );
  }

  static String _providerSubtitle(String apiKey) {
    return apiKey.trim().isEmpty ? '智谱GLM未配置' : '智谱GLM已配置';
  }

  static String _strategySubtitle(AiFinanceParseStrategy strategy) {
    final enabled = <String>[
      if (strategy.splitMultipleBills) '多笔',
      if (strategy.detectTransfers) '转账',
      if (strategy.extractAccounts) '账户',
      if (strategy.extractTags) '标签',
    ];
    if (enabled.isEmpty) {
      return '基础解析 · ${strategy.noteLength.label}';
    }
    return '${enabled.join('、')} · ${strategy.noteLength.label}';
  }

  static String _promptSubtitle(String prompt) {
    return prompt.trim().isEmpty ? '使用默认平生记账提示词' : '已启用自定义提示词';
  }
}

class _FinanceAiProviderManagePage extends StatelessWidget {
  const _FinanceAiProviderManagePage({
    required this.endpoint,
    required this.model,
    required this.apiKey,
    required this.onConfigChanged,
  });

  final String endpoint;
  final String model;
  final String apiKey;
  final void Function({
    required String endpoint,
    required String model,
    required String apiKey,
    AiFinanceParseStrategy? parseStrategy,
    String? customPrompt,
  }) onConfigChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FinanceAiPageHeader(
              title: '服务商管理',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                children: [
                  _FinanceAiSettingsTile(
                    icon: Icons.psychology_alt_rounded,
                    title: '智谱GLM',
                    subtitle: apiKey.trim().isEmpty
                        ? '内置服务商，请填写 API Key'
                        : '文本模型 $model',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => _FinanceAiProviderEditPage(
                          endpoint: endpoint,
                          model: model,
                          apiKey: apiKey,
                          onConfigChanged: onConfigChanged,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceAiParseStrategyPage extends StatefulWidget {
  const _FinanceAiParseStrategyPage({
    required this.strategy,
    required this.onChanged,
  });

  final AiFinanceParseStrategy strategy;
  final ValueChanged<AiFinanceParseStrategy> onChanged;

  @override
  State<_FinanceAiParseStrategyPage> createState() =>
      _FinanceAiParseStrategyPageState();
}

class _FinanceAiParseStrategyPageState
    extends State<_FinanceAiParseStrategyPage> {
  late AiFinanceParseStrategy _strategy;

  @override
  void initState() {
    super.initState();
    _strategy = widget.strategy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FinanceAiPageHeader(
              title: '记账解析策略',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                children: [
                  _FinanceAiStrategySwitch(
                    keyValue: 'ai_parse_strategy_split',
                    icon: Icons.call_split_rounded,
                    title: '多笔账单自动拆分',
                    subtitle: '一句话里有多笔消费时拆成多条记录',
                    value: _strategy.splitMultipleBills,
                    onChanged: (value) => _update(
                      _strategy.copyWith(splitMultipleBills: value),
                    ),
                  ),
                  _FinanceAiStrategySwitch(
                    keyValue: 'ai_parse_strategy_merge',
                    icon: Icons.merge_type_rounded,
                    title: '同一商家一次支付自动合并',
                    subtitle: '同一笔付款内的商品合并成一条记录',
                    value: _strategy.mergeSameMerchant,
                    onChanged: (value) => _update(
                      _strategy.copyWith(mergeSameMerchant: value),
                    ),
                  ),
                  _FinanceAiStrategySwitch(
                    keyValue: 'ai_parse_strategy_transfer',
                    icon: Icons.swap_horiz_rounded,
                    title: '转账识别',
                    subtitle: '识别账户间转入转出，而不是普通收支',
                    value: _strategy.detectTransfers,
                    onChanged: (value) => _update(
                      _strategy.copyWith(detectTransfers: value),
                    ),
                  ),
                  _FinanceAiStrategySwitch(
                    keyValue: 'ai_parse_strategy_accounts',
                    icon: Icons.account_balance_wallet_rounded,
                    title: '账户自动提取',
                    subtitle: '从支付宝、微信、银行卡等文本里提取账户',
                    value: _strategy.extractAccounts,
                    onChanged: (value) => _update(
                      _strategy.copyWith(extractAccounts: value),
                    ),
                  ),
                  _FinanceAiStrategySwitch(
                    keyValue: 'ai_parse_strategy_tags',
                    icon: Icons.sell_rounded,
                    title: '标签自动提取',
                    subtitle: '为报销、自己、工作餐等场景添加标签',
                    value: _strategy.extractTags,
                    onChanged: (value) => _update(
                      _strategy.copyWith(extractTags: value),
                    ),
                  ),
                  _FinanceAiStrategySwitch(
                    keyValue: 'ai_parse_strategy_time',
                    icon: Icons.schedule_rounded,
                    title: '时间智能推断',
                    subtitle: '把昨天、晚上、上周等描述推成具体时间',
                    value: _strategy.inferTime,
                    onChanged: (value) => _update(
                      _strategy.copyWith(inferTime: value),
                    ),
                  ),
                  _FinanceAiStrategySwitch(
                    keyValue: 'ai_parse_strategy_confidence',
                    icon: Icons.rule_rounded,
                    title: '低置信度提醒复核',
                    subtitle: '要求 AI 返回置信度，低把握时提示人工确认',
                    value: _strategy.requireLowConfidenceReview,
                    onChanged: (value) => _update(
                      _strategy.copyWith(requireLowConfidenceReview: value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ModuleSectionTitle(
                    icon: Icons.short_text_rounded,
                    title: '备注长度',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: _financeAiCardDecoration(),
                    child: Column(
                      children: [
                        for (final length in AiFinanceNoteLength.values)
                          _FinanceAiNoteLengthOption(
                            keyValue: 'ai_parse_strategy_note_${length.name}',
                            length: length,
                            selected: _strategy.noteLength == length,
                            onTap: () => _update(
                              _strategy.copyWith(noteLength: length),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: FilledButton(
                      key: const ValueKey('ai_parse_strategy_save'),
                      onPressed: _save,
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _update(AiFinanceParseStrategy strategy) {
    setState(() => _strategy = strategy);
  }

  void _save() {
    widget.onChanged(_strategy);
    Navigator.of(context).pop();
  }
}

class _FinanceAiPromptEditPage extends StatefulWidget {
  const _FinanceAiPromptEditPage({
    required this.prompt,
    required this.onChanged,
  });

  final String prompt;
  final ValueChanged<String> onChanged;

  @override
  State<_FinanceAiPromptEditPage> createState() =>
      _FinanceAiPromptEditPageState();
}

class _FinanceAiPromptEditPageState extends State<_FinanceAiPromptEditPage> {
  late final TextEditingController _controller;
  late String _savedPrompt;

  bool get _hasChanges => _controller.text != _savedPrompt;

  @override
  void initState() {
    super.initState();
    _savedPrompt = widget.prompt.trim().isEmpty
        ? AiFinancePromptBuilder.defaultTemplate
        : widget.prompt;
    _controller = TextEditingController(text: _savedPrompt);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FinanceAiPageHeader(
              title: '提示词编辑',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                children: [
                  _FinanceAiPromptVariablesCard(),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: _financeAiCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.edit_note_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '提示词内容',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            if (_hasChanges)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.financeRed.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '未保存',
                                  style: TextStyle(
                                    color: AppColors.financeRed,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey('ai_prompt_editor_field'),
                          controller: _controller,
                          minLines: 12,
                          maxLines: 20,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.45,
                          ),
                          decoration: InputDecoration(
                            hintText: '输入提示词...',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: _financeAiCardDecoration(),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const ValueKey('ai_prompt_editor_preview'),
                                onPressed: _showPreview,
                                icon: const Icon(Icons.visibility_rounded),
                                label: const Text('预览'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                key: const ValueKey('ai_prompt_editor_save'),
                                onPressed: _hasChanges ? _save : null,
                                icon: const Icon(Icons.save_rounded),
                                label: const Text('保存'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey('ai_prompt_editor_reset'),
                            onPressed: _resetToDefault,
                            icon: const Icon(Icons.restore_rounded),
                            label: const Text('恢复默认'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final displayedPrompt = _controller.text;
    final storedPrompt =
        displayedPrompt == AiFinancePromptBuilder.defaultTemplate
            ? ''
            : displayedPrompt;
    setState(() => _savedPrompt = displayedPrompt);
    widget.onChanged(storedPrompt);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('提示词已保存')),
    );
  }

  void _resetToDefault() {
    setState(() => _controller.text = AiFinancePromptBuilder.defaultTemplate);
  }

  void _showPreview() {
    final preview = const AiFinancePromptBuilder().build(
      text: '昨天中午吃饭50，晚上奶茶12',
      now: DateTime(2026, 6, 5, 8, 30),
      customPrompt: _controller.text,
    );
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示词预览'),
          content: SingleChildScrollView(
            child: SelectableText(
              preview,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}

class _FinanceAiPromptVariablesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const variables = [
      ('{{INPUT_SOURCE}}', '输入来源描述，例如自然语言或账单图片'),
      ('{{CURRENT_TIME}}', '当前日期时间，例如 2026-06-05 08:30'),
      ('{{CURRENT_DATE}}', '当前日期，例如 2026-06-05'),
      ('{{OCR_TEXT}}', '用户输入文字或图片识别任务描述'),
      ('{{CATEGORIES}}', '平生内置收支分类列表'),
      ('{{ACCOUNTS}}', '可用账户列表'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: _financeAiCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.code_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '可用变量',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final variable in variables)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      variable.$1,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      variable.$2,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FinanceAiProviderEditPage extends StatefulWidget {
  const _FinanceAiProviderEditPage({
    required this.endpoint,
    required this.model,
    required this.apiKey,
    required this.onConfigChanged,
  });

  final String endpoint;
  final String model;
  final String apiKey;
  final void Function({
    required String endpoint,
    required String model,
    required String apiKey,
    AiFinanceParseStrategy? parseStrategy,
    String? customPrompt,
  }) onConfigChanged;

  @override
  State<_FinanceAiProviderEditPage> createState() =>
      _FinanceAiProviderEditPageState();
}

class _FinanceAiProviderEditPageState
    extends State<_FinanceAiProviderEditPage> {
  late final TextEditingController _endpointController;
  late final TextEditingController _modelController;
  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController(
      text: widget.endpoint.trim().isEmpty
          ? defaultGlmChatEndpoint
          : widget.endpoint,
    );
    _modelController = TextEditingController(
      text: widget.model.trim().isEmpty ? defaultGlmTextModel : widget.model,
    );
    _apiKeyController = TextEditingController(text: widget.apiKey);
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FinanceAiPageHeader(
              title: '智谱GLM',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: _financeAiCardDecoration(),
                    child: Column(
                      children: [
                        _FinanceTextField(
                          keyValue: 'ai_provider_endpoint',
                          controller: _endpointController,
                          label: 'API 地址',
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 10),
                        _FinanceTextField(
                          keyValue: 'ai_provider_text_model',
                          controller: _modelController,
                          label: '文本模型',
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey('ai_provider_api_key'),
                          controller: _apiKeyController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'API Key',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    widget.onConfigChanged(
      endpoint: _endpointController.text,
      model: _modelController.text,
      apiKey: _apiKeyController.text,
    );
    final navigator = Navigator.of(context);
    navigator.pop();
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

class _FinanceAiPageHeader extends StatelessWidget {
  const _FinanceAiPageHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _FinanceAiSettingsTile extends StatelessWidget {
  const _FinanceAiSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: _financeAiCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceAiStrategySwitch extends StatelessWidget {
  const _FinanceAiStrategySwitch({
    required this.keyValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String keyValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: _financeAiCardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: ValueKey(keyValue),
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FinanceAiNoteLengthOption extends StatelessWidget {
  const _FinanceAiNoteLengthOption({
    required this.keyValue,
    required this.length,
    required this.selected,
    required this.onTap,
  });

  final String keyValue;
  final AiFinanceNoteLength length;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey(keyValue),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  length.label,
                  style: TextStyle(
                    color: selected ? AppColors.ink : AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceAiCapabilityTile extends StatelessWidget {
  const _FinanceAiCapabilityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.muted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: _financeAiCardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _financeAiCardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.line),
  );
}
