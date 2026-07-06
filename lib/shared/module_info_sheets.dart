// 中文注释：跨模块共享 UI 组件，负责统一卡片、导航、弹层和模块外壳。

part of 'shared.dart';

class _AboutAppSheet extends StatelessWidget {
  const _AboutAppSheet();

  @override
  Widget build(BuildContext context) {
    return InfoSheetFrame(
      title: '关于 App',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _AboutHero(),
          SizedBox(height: 18),
          _FeatureIntroCard(
            icon: Icons.account_balance_wallet_rounded,
            title: '财务管理',
            body: '收支记录、资产统计、趋势分析',
            color: Color(0xFF7F7AF7),
          ),
          _FeatureIntroCard(
            icon: Icons.monitor_heart_rounded,
            title: '健康数据',
            body: '运动锻炼、睡眠心率、能量消耗',
            color: Color(0xFFFF747C),
          ),
          _FeatureIntroCard(
            icon: Icons.event_available_rounded,
            title: '计划待办',
            body: '日历视图、待办清单、分类管理',
            color: Color(0xFF7D9CFF),
          ),
          _FeatureIntroCard(
            icon: Icons.fitness_center_rounded,
            title: '科学锻炼',
            body: '训练计划、动作指导、数据追踪',
            color: AppColors.primary,
          ),
          _FeatureIntroCard(
            icon: Icons.restaurant_rounded,
            title: '饮食记录',
            body: '热量计算、食物分类、饮食分析',
            color: AppColors.success,
          ),
          SizedBox(height: 12),
          Center(
            child: Text(
              '一个 App 管理你的全部生活',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const AppIconMark(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '平生',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '全能生活助手',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '财务、健康、计划、饮食一站管理',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
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

class _FeatureIntroCard extends StatelessWidget {
  const _FeatureIntroCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _GuideSheet extends StatelessWidget {
  const _GuideSheet();

  @override
  Widget build(BuildContext context) {
    return InfoSheetFrame(
      title: '使用指导',
      child: Column(
        children: const [
          _GuideStep(
            number: '1',
            title: '底部切换模块',
            body: '主页面最底部固定显示财务、计划、饮食、锻炼、健康，随时点对应入口切换大模块。',
          ),
          _GuideStep(
            number: '2',
            title: '先安排今天',
            body: '计划模块负责今天要做什么：新增待办、设置分类优先级，或把无日期任务放进待办箱再安排到本周。',
          ),
          _GuideStep(
            number: '3',
            title: '记录饮食和训练',
            body: '饮食按餐次记录食物和热量，锻炼按动作完成组数；训练后可以直接去饮食补一条加餐。',
          ),
          _GuideStep(
            number: '4',
            title: '看联动和小组件',
            body: '财务、饮食、锻炼和健康数据会汇总到今日联动，也会同步到桌面小组件；健康页可连接 Health Connect。',
          ),
          _GuideStep(
            number: '5',
            title: '本地优先保存',
            body: 'App 主数据优先写入本地数据库，小组件只保留摘要；登录态和服务端账号用于后续同步扩展。',
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
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

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  static const _api = _PingShengApi();
  static const _contactFallback = '客服联系方式：请在当前测试群或部署者提供的联系方式中反馈。';
  static const _types = ['问题', '建议', '崩溃', '界面显示', '数据异常', '其他'];

  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  String _type = _types.first;
  bool _submitting = false;
  String? _error;
  FeedbackReceipt? _receipt;

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InfoSheetFrame(
      title: '问题反馈',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in _types)
                ChoiceChip(
                  key: ValueKey('feedback_type_$type'),
                  label: Text(type),
                  selected: _type == type,
                  onSelected:
                      _submitting ? null : (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('feedback_content'),
            controller: _contentController,
            minLines: 5,
            maxLines: 7,
            enabled: !_submitting,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: '写下你遇到的问题或想要的功能',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('feedback_contact'),
            controller: _contactController,
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: '联系方式（选填，微信/手机号/邮箱）',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const ValueKey('feedback_submit'),
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _submitting ? '提交中...' : '提交反馈',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            EmptyCard(title: '提交失败', subtitle: _error!),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('feedback_copy_content'),
                  onPressed: _copyFeedbackContent,
                  child: const Text('复制反馈内容'),
                ),
                OutlinedButton(
                  key: const ValueKey('feedback_copy_contact'),
                  onPressed: _copyContactFallback,
                  child: const Text('复制联系方式'),
                ),
              ],
            ),
          ],
          if (_receipt != null) ...[
            const SizedBox(height: 14),
            EmptyCard(
              title: '已提交',
              subtitle: '反馈编号 ${_receipt!.id}，我们会尽快处理。',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.length < 5) {
      setState(() {
        _error = '请至少写 5 个字';
        _receipt = null;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _receipt = null;
    });
    try {
      final receipt = await _api.submitFeedback(
        FeedbackDraft(
          type: _type,
          content: content,
          contact: _contactController.text.trim(),
          platform: 'android',
          appVersionName: appVersionName,
          appVersionCode: appVersionCode,
          deviceInfo: defaultTargetPlatform.name,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() => _receipt = receipt);
    } on _ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '提交失败，请稍后重试。');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _copyFeedbackContent() async {
    await Clipboard.setData(
      ClipboardData(
        text:
            '类型：$_type\n内容：${_contentController.text.trim()}\n联系方式：${_contactController.text.trim()}',
      ),
    );
  }

  Future<void> _copyContactFallback() async {
    await Clipboard.setData(const ClipboardData(text: _contactFallback));
  }
}

class _PingShengApi {
  const _PingShengApi();

  Future<FeedbackReceipt> submitFeedback(FeedbackDraft draft) async {
    final base = Uri.parse(apiBaseUrl);
    final uri = base.replace(path: '${base.path}/v1/feedback');
    final bodyBytes = utf8.encode(jsonEncode(draft.toJson()));
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
        throw _ApiException(
          (error?['message'] as String?) ?? '请求失败：${response.statusCode}',
        );
      }
      return FeedbackReceipt.fromJson(json);
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
  const _ApiException(this.message);

  final String message;
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
