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
  final _controller = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InfoSheetFrame(
      title: '问题反馈',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            minLines: 5,
            maxLines: 7,
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                setState(() => _sent = true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '提交反馈',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (_sent) ...[
            const SizedBox(height: 14),
            const EmptyCard(
              title: '已收到',
              subtitle: '原型里先做本地反馈状态，后续可以接入邮件、接口或工单系统。',
            ),
          ],
        ],
      ),
    );
  }
}
