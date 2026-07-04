// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

class _FinanceAiAssistantPage extends StatefulWidget {
  const _FinanceAiAssistantPage({
    required this.endpoint,
    required this.model,
    required this.apiKey,
    required this.parseStrategy,
    required this.customPrompt,
    required this.onConfigChanged,
    required this.onSaveAll,
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
  final ValueChanged<List<FinanceRecord>> onSaveAll;

  @override
  State<_FinanceAiAssistantPage> createState() =>
      _FinanceAiAssistantPageState();
}

class _FinanceAiAssistantPageState extends State<_FinanceAiAssistantPage> {
  final _client = AiFinanceClient();
  final _imagePicker = ImagePicker();
  late final TextEditingController _inputController;
  final List<_FinanceAiAssistantMessage> _messages = [];
  late String _endpoint;
  late String _model;
  late String _apiKey;
  late AiFinanceParseStrategy _parseStrategy;
  late String _customPrompt;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _endpoint = widget.endpoint;
    _model = widget.model;
    _apiKey = widget.apiKey;
    _parseStrategy = widget.parseStrategy;
    _customPrompt = widget.customPrompt;
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
              onPickImage: _pickBillImage,
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
          parseStrategy: _parseStrategy,
          customPrompt: _customPrompt,
          onConfigChanged: _updateConfig,
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
        strategy: _parseStrategy,
        customPrompt: _customPrompt,
      );
      _saveBills(bills);
      _inputController.clear();
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

  Future<void> _pickBillImage() async {
    if (_loading) {
      return;
    }
    if (_apiKey.trim().isEmpty) {
      _appendAssistantMessage('请先填写 AI 接口 Key，再使用图片理解', isError: true);
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        // 真机相册原图很容易过大，先缩到适合账单识别的尺寸再转 base64 上传。
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (image == null) {
        return;
      }

      setState(() {
        _messages.add(_FinanceAiAssistantMessage.user('已选择图片：${image.name}'));
        _loading = true;
      });
      final bills = await _client.parseImage(
        imageBytes: await image.readAsBytes(),
        mimeType: _mimeTypeForImageName(image.name),
        apiKey: _apiKey,
        endpoint: _endpoint,
        model: '',
        strategy: _parseStrategy,
        customPrompt: _customPrompt,
      );
      _saveBills(bills);
    } on PlatformException catch (error) {
      if (mounted) {
        _appendAssistantMessage(
          '图片权限或相册读取失败：${error.message ?? error.code}',
          isError: true,
        );
      }
    } on AiFinanceException catch (error) {
      if (mounted) {
        _appendAssistantMessage(error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        _appendAssistantMessage('图片理解失败：$error', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _saveBills(List<AiFinanceBillInfo> bills) {
    final records = bills.map(financeRecordFromAiBill).toList();
    widget.onSaveAll(records);
    if (!mounted) {
      return;
    }
    _appendAssistantMessage(
      '已生成 ${records.length} 笔财务记录，可在记录页查看。',
    );
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
    required this.onPickImage,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool loading;
  final ValueChanged<_AiFinanceQuickCommand> onQuickCommand;
  final VoidCallback onPickImage;
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
              _FinanceAiIconButton(
                keyValue: 'ai_finance_pick_image',
                tooltip: '图片理解',
                icon: Icons.image_search_rounded,
                onPressed: loading ? null : onPickImage,
              ),
              const SizedBox(width: 8),
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

class _FinanceAiIconButton extends StatelessWidget {
  const _FinanceAiIconButton({
    required this.keyValue,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String keyValue;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 44,
      child: IconButton(
        key: ValueKey(keyValue),
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(icon, size: 19),
      ),
    );
  }
}

String _mimeTypeForImageName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
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
