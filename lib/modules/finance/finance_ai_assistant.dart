part of '../../main.dart';

class _FinanceAiAssistantPage extends StatefulWidget {
  const _FinanceAiAssistantPage({
    required this.endpoint,
    required this.model,
    required this.apiKey,
    required this.onConfigChanged,
    required this.onSaveAll,
  });

  final String endpoint;
  final String model;
  final String apiKey;
  final void Function({
    required String endpoint,
    required String model,
    required String apiKey,
  }) onConfigChanged;
  final ValueChanged<List<FinanceRecord>> onSaveAll;

  @override
  State<_FinanceAiAssistantPage> createState() =>
      _FinanceAiAssistantPageState();
}

class _FinanceAiAssistantPageState extends State<_FinanceAiAssistantPage> {
  final _client = AiFinanceClient();
  late final TextEditingController _inputController;
  final List<_FinanceAiAssistantMessage> _messages = [];
  late String _endpoint;
  late String _model;
  late String _apiKey;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _endpoint = widget.endpoint;
    _model = widget.model;
    _apiKey = widget.apiKey;
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsConfig = _apiKey.trim().isEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FinanceAiAssistantHeader(
              onClose: () => Navigator.of(context).pop(),
              onOpenSettings: _openSettings,
            ),
            if (needsConfig)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                child: _FinanceAiConfigBanner(onOpenSettings: _openSettings),
              ),
            Expanded(
              child: _messages.isEmpty
                  ? const _FinanceAiEmptyMessages()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                      itemBuilder: (context, index) {
                        return _FinanceAiMessageBubble(
                          message: _messages[index],
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: _messages.length,
                    ),
            ),
            _FinanceAiComposer(
              controller: _inputController,
              loading: _loading,
              onQuickCommand: _applyQuickCommand,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _FinanceAiSettingsPage(
          endpoint: _endpoint,
          model: _model,
          apiKey: _apiKey,
          onConfigChanged: _updateConfig,
        ),
      ),
    );
  }

  void _updateConfig({
    required String endpoint,
    required String model,
    required String apiKey,
  }) {
    final nextEndpoint =
        endpoint.trim().isEmpty ? _defaultGlmChatEndpoint : endpoint.trim();
    final nextModel =
        model.trim().isEmpty ? _defaultGlmTextModel : model.trim();
    final nextApiKey = apiKey.trim();
    setState(() {
      _endpoint = nextEndpoint;
      _model = nextModel;
      _apiKey = nextApiKey;
    });
    widget.onConfigChanged(
      endpoint: nextEndpoint,
      model: nextModel,
      apiKey: nextApiKey,
    );
  }

  void _applyQuickCommand(_AiFinanceQuickCommand command) {
    _inputController.text = command.prompt;
    _inputController.selection = TextSelection.collapsed(
      offset: _inputController.text.length,
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      _appendAssistantMessage('请先输入要记账的内容', isError: true);
      return;
    }
    setState(() {
      _messages.add(_FinanceAiAssistantMessage.user(text));
    });
    if (_apiKey.trim().isEmpty) {
      _appendAssistantMessage('请先填写 AI 接口 Key', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final bills = await _client.parseText(
        text: text,
        apiKey: _apiKey,
        endpoint: _endpoint,
        model: _model,
      );
      final records = bills.map(financeRecordFromAiBill).toList();
      widget.onSaveAll(records);
      if (!mounted) {
        return;
      }
      _inputController.clear();
      _appendAssistantMessage(
        '已生成 ${records.length} 笔财务记录，可在记录页查看。',
      );
    } on AiFinanceException catch (error) {
      if (mounted) {
        _appendAssistantMessage(error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        _appendAssistantMessage('AI 记账失败：$error', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _appendAssistantMessage(String text, {bool isError = false}) {
    setState(() {
      _messages.add(
        _FinanceAiAssistantMessage.assistant(text, isError: isError),
      );
    });
  }
}

class _FinanceAiAssistantHeader extends StatelessWidget {
  const _FinanceAiAssistantHeader({
    required this.onClose,
    required this.onOpenSettings,
  });

  final VoidCallback onClose;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: '关闭',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'AI助手',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '设置',
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
    );
  }
}

class _FinanceAiConfigBanner extends StatelessWidget {
  const _FinanceAiConfigBanner({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.key_off_rounded,
            color: AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '未配置 AI 服务商，请先在设置中添加并绑定',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: onOpenSettings,
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
}

class _FinanceAiEmptyMessages extends StatelessWidget {
  const _FinanceAiEmptyMessages();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '暂无消息',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '可以直接说“昨天午饭 50，奶茶 12”。',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceAiComposer extends StatelessWidget {
  const _FinanceAiComposer({
    required this.controller,
    required this.loading,
    required this.onQuickCommand,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool loading;
  final ValueChanged<_AiFinanceQuickCommand> onQuickCommand;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FinanceAiQuickCommandBar(onSelected: onQuickCommand),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('ai_finance_input'),
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: '输入一句话记账',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                height: 44,
                child: FilledButton(
                  key: const ValueKey('send_ai_finance_message'),
                  onPressed: loading ? null : onSend,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceAiQuickCommandBar extends StatelessWidget {
  const _FinanceAiQuickCommandBar({required this.onSelected});

  final ValueChanged<_AiFinanceQuickCommand> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final command = _aiFinanceQuickCommands[index];
          return Material(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              key: ValueKey('ai_assistant_quick_${command.key}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelected(command),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(command.icon, size: 15, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      command.label,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _aiFinanceQuickCommands.length,
      ),
    );
  }
}

class _FinanceAiAssistantMessage {
  const _FinanceAiAssistantMessage({
    required this.text,
    required this.fromUser,
    this.isError = false,
  });

  factory _FinanceAiAssistantMessage.user(String text) {
    return _FinanceAiAssistantMessage(text: text, fromUser: true);
  }

  factory _FinanceAiAssistantMessage.assistant(
    String text, {
    bool isError = false,
  }) {
    return _FinanceAiAssistantMessage(
      text: text,
      fromUser: false,
      isError: isError,
    );
  }

  final String text;
  final bool fromUser;
  final bool isError;
}

class _FinanceAiMessageBubble extends StatelessWidget {
  const _FinanceAiMessageBubble({required this.message});

  final _FinanceAiAssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final align =
        message.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.fromUser
        ? AppColors.primary
        : message.isError
            ? AppColors.financeRed.withValues(alpha: 0.10)
            : AppColors.surface;
    final textColor = message.fromUser
        ? Colors.white
        : message.isError
            ? AppColors.financeRed
            : AppColors.ink;
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(8),
            border: message.fromUser
                ? null
                : Border.all(
                    color: message.isError
                        ? AppColors.financeRed.withValues(alpha: 0.22)
                        : AppColors.line,
                  ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FinanceAiSettingsPage extends StatefulWidget {
  const _FinanceAiSettingsPage({
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
  }) onConfigChanged;

  @override
  State<_FinanceAiSettingsPage> createState() => _FinanceAiSettingsPageState();
}

class _FinanceAiSettingsPageState extends State<_FinanceAiSettingsPage> {
  bool _enabled = true;

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
                    subtitle: _providerSubtitle(widget.apiKey),
                    onTap: _openProviderManage,
                  ),
                  const SizedBox(height: 16),
                  const _ModuleSectionTitle(
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
                    subtitle: '暂未绑定',
                    active: false,
                  ),
                  const _FinanceAiCapabilityTile(
                    icon: Icons.graphic_eq_rounded,
                    title: '语音转文字',
                    subtitle: '暂未绑定',
                    active: false,
                  ),
                  const SizedBox(height: 16),
                  const _ModuleSectionTitle(
                    icon: Icons.tune_rounded,
                    title: '高级设置',
                  ),
                  const SizedBox(height: 10),
                  _FinanceAiSettingsTile(
                    icon: Icons.receipt_long_rounded,
                    title: '记账解析策略',
                    subtitle: '多笔账单、转账、账户和标签自动提取',
                    onTap: () {},
                    showArrow: false,
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
          endpoint: widget.endpoint,
          model: widget.model,
          apiKey: widget.apiKey,
          onConfigChanged: widget.onConfigChanged,
        ),
      ),
    );
  }

  static String _providerSubtitle(String apiKey) {
    return apiKey.trim().isEmpty ? '智谱GLM未配置' : '智谱GLM已配置';
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
          ? _defaultGlmChatEndpoint
          : widget.endpoint,
    );
    _modelController = TextEditingController(
      text: widget.model.trim().isEmpty ? _defaultGlmTextModel : widget.model,
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
    this.showArrow = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showArrow;

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
            if (showArrow)
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
