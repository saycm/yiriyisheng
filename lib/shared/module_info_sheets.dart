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
        children: [
          const _AboutHero(),
          const SizedBox(height: 18),
          const _InfoSectionTitle(
            icon: Icons.dashboard_customize_rounded,
            title: '它是什么',
          ),
          const SizedBox(height: 10),
          const _AboutSummaryCard(
            title: '本地优先的生活工作台',
            body:
                '平生把计划、财务、饮食、锻炼、状态和桌面小组件放在同一个日常流程里。它不是只做单项记录，而是帮助你回答：今天要做什么、花了什么、吃了什么、练了什么、身体状态能不能承受当前安排。',
          ),
          const SizedBox(height: 18),
          const _InfoSectionTitle(
            icon: Icons.apps_rounded,
            title: '当前模块',
          ),
          const SizedBox(height: 10),
          const _FeatureIntroCard(
            icon: Icons.event_available_rounded,
            title: '计划',
            body:
                '今日执行、待办箱、周计划和复盘。待办支持分类、优先级、备注、重复规则和模块联动；任务完成、延后、归档都走明确按钮，减少误触。',
            color: Color(0xFF7D9CFF),
          ),
          const _FeatureIntroCard(
            icon: Icons.account_balance_wallet_rounded,
            title: '财务',
            body:
                '手动记账、AI 记账、收支账本、账户资产、分类预算、固定支出、财产健康和趋势图。资产余额由真实账单推导，趋势按真实收支记录聚合。',
            color: Color(0xFF7F7AF7),
          ),
          const _FeatureIntroCard(
            icon: Icons.restaurant_rounded,
            title: '饮食',
            body: '按早餐、午餐、晚餐和夜宵记录食物，支持食物分类、自定义食物、模板和热量/营养汇总。饮食数据会进入健康状态和计划复盘。',
            color: AppColors.success,
          ),
          const _FeatureIntroCard(
            icon: Icons.fitness_center_rounded,
            title: '锻炼',
            body: '内置动作库、训练计划、动作详情、组数记录、休息计时、训练反馈和历史记录。完成训练后可以联动饮食补充摄入。',
            color: AppColors.primary,
          ),
          const _FeatureIntroCard(
            icon: Icons.monitor_heart_rounded,
            title: '状态',
            body:
                '状态中心整合手动身体记录、饮食摄入、锻炼负载和计划压力。Health Connect 是可选外部数据源，可补充步数、睡眠、心率和能量参考。',
            color: Color(0xFFFF747C),
          ),
          const _FeatureIntroCard(
            icon: Icons.widgets_rounded,
            title: '桌面小组件',
            body:
                '展示今日待办、饮食、锻炼、今日支出和今日收入摘要。需要输入内容的操作会回到 App 的真实编辑流程，避免小组件误触直接改数据。',
            color: AppColors.sun,
          ),
          const SizedBox(height: 18),
          const _InfoSectionTitle(
            icon: Icons.lock_outline_rounded,
            title: '数据边界',
          ),
          const SizedBox(height: 10),
          const _AboutSummaryCard(
            title: '核心生活数据保存在本机',
            body:
                '待办、账单、饮食、锻炼和状态记录优先写入本地 SQLite。桌面小组件只保存必要摘要；服务端主要负责账号、登录状态、版本更新和 APK 分发。Health Connect 权限是可选项，关闭后不影响手动记录。',
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
    return GlassSurface(
      borderRadius: 16,
      color: AppColors.surface.withValues(alpha: 0.80),
      padding: const EdgeInsets.all(20),
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
                  '本地优先生活工作台',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '计划、财务、饮食、锻炼、状态和小组件联动',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.78),
        padding: const EdgeInsets.all(14),
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
                      height: 1.45,
                      fontWeight: FontWeight.w700,
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

class _GuideSheet extends StatelessWidget {
  const _GuideSheet();

  @override
  Widget build(BuildContext context) {
    return InfoSheetFrame(
      title: '使用指导',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _GuideIntroCard(),
          SizedBox(height: 16),
          _InfoSectionTitle(
            icon: Icons.route_rounded,
            title: '常用流程',
          ),
          SizedBox(height: 10),
          _GuideQuestion(
            question: '第一次打开应该从哪里开始？',
            answer:
                '先看底部主导航：财务、计划、饮食、锻炼、状态。建议先进入计划，把今天必须做的事放到“今日执行”；没有确定日期的事先放进“待办箱”，再到“周计划”里分配到具体日期。',
          ),
          _GuideQuestion(
            question: '计划模块怎么用才不乱？',
            answer:
                '今日执行适合放今天要完成的少量重点事项；待办箱适合收集暂时没排期的任务；周计划适合把待办安排到未来 7 天；复盘会把完成情况、延后任务、饮食和锻炼联动放在一起看。',
          ),
          _GuideQuestion(
            question: '待办怎么完成、延后或归档？',
            answer:
                '任务卡片不会因为轻点卡片就直接完成。需要点明确的“完成”“延后”或“归档”按钮后才会改变状态。完成后如果任务关联了饮食、锻炼等模块，可以继续进入对应记录流程。',
          ),
          _GuideQuestion(
            question: '财务记录怎么保持真实？',
            answer:
                '可以手动新增收入或支出，也可以配置 AI 小助手后用文字或图片识别账单。资产、今日支出、今日收入、分类预算、固定支出压力和趋势图都基于真实账单记录，不再使用演示固定数值。',
          ),
          _GuideQuestion(
            question: '饮食和锻炼为什么会影响状态？',
            answer:
                '饮食记录会提供今日摄入和营养参考；锻炼记录会提供完成组数、训练负载和反馈。状态中心会把这些数据和手动身体状态一起计算，提示今天适合保持节奏、减压还是降低训练强度。',
          ),
          _GuideQuestion(
            question: 'Health Connect 必须开启吗？',
            answer:
                '不是必须。没有授权或设备不支持时，状态中心仍然可以用手动记录、饮食、锻炼和计划数据正常工作。授权后，App 会额外读取步数、睡眠、心率和能量等系统健康参考。',
          ),
          _GuideQuestion(
            question: '桌面小组件能做什么？',
            answer:
                '小组件主要负责快速查看摘要：待办、饮食、锻炼、今日支出、今日收入和今日消耗。需要输入文字、金额或食物名称的操作会打开 App 对应编辑弹层，避免在桌面上一点就写入错误数据。',
          ),
          _GuideQuestion(
            question: '数据会不会丢？',
            answer:
                'App 主数据优先写入本机 SQLite；保存失败时会明确提示。桌面小组件只同步摘要，不是主数据库。服务器目前主要用于账号、登录续期、版本检查、安装包下载和后续扩展能力。',
          ),
          _GuideQuestion(
            question: '更新从哪里来？',
            answer:
                'App 启动时会检查服务端更新策略。发现新版本时会展示版本号、更新说明和下载地址；强制更新只在低于最低支持版本时触发。安装包由服务器 downloads 目录提供。',
          ),
        ],
      ),
    );
  }
}

class _InfoSectionTitle extends StatelessWidget {
  const _InfoSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AboutSummaryCard extends StatelessWidget {
  const _AboutSummaryCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideIntroCard extends StatelessWidget {
  const _GuideIntroCard();

  @override
  Widget build(BuildContext context) {
    return const EmptyCard(
      title: '先记录，再联动，最后复盘',
      subtitle: '平生的使用方式不是每个模块各记各的，而是让计划、账本、饮食、锻炼和状态围绕“今天”互相补充。下面按常见问题说明怎么用。',
    );
  }
}

class _GuideQuestion extends StatelessWidget {
  const _GuideQuestion({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.78),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.help_outline_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    answer,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.55,
                      fontWeight: FontWeight.w700,
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

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _copied = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _copyFeedback() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    _focusNode.requestFocus();
    final focusContext = _focusNode.context;
    if (focusContext == null) {
      return;
    }
    Actions.invoke(focusContext, CopySelectionTextIntent.copy);
    setState(() => _copied = true);
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
            focusNode: _focusNode,
            minLines: 5,
            maxLines: 7,
            onChanged: (_) => setState(() => _copied = false),
            cursorColor: AppColors.primary,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: '写下你遇到的问题或想要的功能',
              hintStyle: TextStyle(
                color: AppColors.muted.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
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
              onPressed: _controller.text.trim().isEmpty ? null : _copyFeedback,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '复制反馈内容',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (_copied) ...[
            const SizedBox(height: 14),
            const EmptyCard(
              title: '已复制，尚未发送',
              subtitle: '请将反馈内容粘贴到你选择的沟通渠道后发送。',
            ),
          ],
        ],
      ),
    );
  }
}
