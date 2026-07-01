part of '../main.dart';

BoxShadow _airyShadow([Color color = AppColors.primary]) {
  return BoxShadow(
    color: color.withValues(alpha: 0.11),
    blurRadius: 22,
    offset: const Offset(0, 10),
  );
}

BoxDecoration _airyCardDecoration({
  Color color = AppColors.surface,
  Color? borderColor,
  List<BoxShadow>? shadows,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor ?? AppColors.line),
    boxShadow: shadows ?? [_airyShadow()],
  );
}

class PlaceholderModulePage extends StatelessWidget {
  const PlaceholderModulePage({
    super.key,
    required this.module,
    required this.onOpenModules,
    required this.onSwitchModule,
  });

  final LifeModule module;
  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;

  @override
  Widget build(BuildContext context) {
    final info = switch (module) {
      LifeModule.food => (
          '饮食',
          Icons.restaurant_rounded,
          '下一张会按 1.png/2.png 做食物添加、分类选择、卡路里合计。'
        ),
      LifeModule.workout => (
          '锻炼',
          Icons.fitness_center_rounded,
          '下一步会按 8.png/6.png 做训练列表、动作组、开始动作。'
        ),
      LifeModule.health => (
          '健康',
          Icons.monitor_heart_rounded,
          '后续会按 9.png 做健康圆环、睡眠、步数、心率、能量卡片。'
        ),
      _ => ('模块', Icons.apps_rounded, '这个模块马上补。'),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  _IconBubble(
                    icon: Icons.view_sidebar_rounded,
                    color: const Color(0xFF91A3FF),
                    onTap: onOpenModules,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        info.$1,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  _IconBubble(
                    icon: Icons.more_horiz_rounded,
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _EmptyCard(
                title: info.$1,
                subtitle: info.$3,
              ),
              const Spacer(),
              _ModuleQuickNav(
                selected: module,
                onSwitchModule: onSwitchModule,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleSheet extends StatelessWidget {
  const _ModuleSheet({
    required this.selected,
    required this.pendingTodos,
    required this.foodCalories,
    required this.workoutGroups,
    required this.todayExpense,
    required this.events,
    required this.onSelect,
    this.onSignOut,
  });

  final LifeModule selected;
  final int pendingTodos;
  final int foodCalories;
  final int workoutGroups;
  final double todayExpense;
  final List<LifeEvent> events;
  final ValueChanged<LifeModule> onSelect;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              _IconBubble(
                icon: Icons.close_rounded,
                color: const Color(0xFF9A8FF7),
                onTap: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    '功能模块',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 42),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              key: const ValueKey('module_sheet_scroll'),
              children: [
                _ModuleTodaySummaryBar(
                  pendingTodos: pendingTodos,
                  foodCalories: foodCalories,
                  workoutGroups: workoutGroups,
                ),
                const SizedBox(height: 14),
                _ModuleCenterGrid(
                  selected: selected,
                  pendingTodos: pendingTodos,
                  foodCalories: foodCalories,
                  workoutGroups: workoutGroups,
                  todayExpense: todayExpense,
                  onSelect: onSelect,
                  onOpenSettings: () => _showSettingsSheet(context),
                ),
                const SizedBox(height: 14),
                _ModuleRecentEventsCard(events: events.take(3).toList()),
                const SizedBox(height: 14),
                const _ModuleSectionTitle(
                  icon: Icons.more_horiz_rounded,
                  title: '更多',
                ),
                const SizedBox(height: 10),
                _ModuleListItem(
                  icon: Icons.info_outline_rounded,
                  title: '关于 App',
                  onTap: () => _showAboutSheet(context),
                ),
                _ModuleListItem(
                  icon: Icons.article_outlined,
                  title: '使用指导',
                  onTap: () => _showGuideSheet(context),
                ),
                _ModuleListItem(
                  icon: Icons.edit_rounded,
                  title: '问题反馈',
                  onTap: () => _showFeedbackSheet(context),
                ),
                if (onSignOut != null) ...[
                  const SizedBox(height: 8),
                  _ModuleListItem(
                    icon: Icons.logout_rounded,
                    title: '退出登录',
                    iconColor: AppColors.financeRed,
                    titleColor: AppColors.financeRed,
                    onTap: () {
                      Navigator.of(context).pop();
                      unawaited(onSignOut!());
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AboutAppSheet(),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SettingsSheet(),
    );
  }

  void _showGuideSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GuideSheet(),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FeedbackSheet(),
    );
  }
}

class _ModuleTodaySummaryBar extends StatelessWidget {
  const _ModuleTodaySummaryBar({
    required this.pendingTodos,
    required this.foodCalories,
    required this.workoutGroups,
  });

  final int pendingTodos;
  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('module_today_summary'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderColor: AppColors.line,
        shadows: [_airyShadow(AppColors.sky)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 7),
              Text(
                '今日状态',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModuleSummaryChip(text: '待办 $pendingTodos 项'),
              _ModuleSummaryChip(text: '饮食 $foodCalories kcal'),
              _ModuleSummaryChip(text: '锻炼 $workoutGroups 组'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleSummaryChip extends StatelessWidget {
  const _ModuleSummaryChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ModuleCenterGrid extends StatelessWidget {
  const _ModuleCenterGrid({
    required this.selected,
    required this.pendingTodos,
    required this.foodCalories,
    required this.workoutGroups,
    required this.todayExpense,
    required this.onSelect,
    required this.onOpenSettings,
  });

  final LifeModule selected;
  final int pendingTodos;
  final int foodCalories;
  final int workoutGroups;
  final double todayExpense;
  final ValueChanged<LifeModule> onSelect;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final financeText =
        todayExpense > 0 ? '今日支出 ¥${_formatModuleMoney(todayExpense)}' : '查看账本';
    final healthText = foodCalories > 0 || workoutGroups > 0 ? '今日有记录' : '未记录';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ModuleSectionTitle(
          icon: Icons.grid_view_rounded,
          title: '模块状态',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 10) / 2;
            Widget tile(Widget child) {
              return SizedBox(width: tileWidth, child: child);
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_plan'),
                    icon: Icons.event_available_rounded,
                    title: '计划',
                    status: '$pendingTodos 项待办',
                    selected: selected == LifeModule.plan,
                    onTap: () => onSelect(LifeModule.plan),
                  ),
                ),
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_finance'),
                    icon: Icons.account_balance_wallet_rounded,
                    title: '财务',
                    status: financeText,
                    selected: selected == LifeModule.finance,
                    onTap: () => onSelect(LifeModule.finance),
                  ),
                ),
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_food'),
                    icon: Icons.restaurant_rounded,
                    title: '饮食',
                    status: '$foodCalories kcal',
                    selected: selected == LifeModule.food,
                    onTap: () => onSelect(LifeModule.food),
                  ),
                ),
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_workout'),
                    icon: Icons.fitness_center_rounded,
                    title: '锻炼',
                    status: '$workoutGroups 组训练',
                    selected: selected == LifeModule.workout,
                    onTap: () => onSelect(LifeModule.workout),
                  ),
                ),
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_health'),
                    icon: Icons.monitor_heart_rounded,
                    title: '健康',
                    status: healthText,
                    selected: selected == LifeModule.health,
                    onTap: () => onSelect(LifeModule.health),
                  ),
                ),
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_settings'),
                    icon: Icons.settings_rounded,
                    title: '设置',
                    status: '账号与偏好',
                    selected: false,
                    onTap: onOpenSettings,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ModuleCenterTile extends StatelessWidget {
  const _ModuleCenterTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: tileKey,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: _airyCardDecoration(
          color: selected
              ? AppColors.primarySoft.withValues(alpha: 0.9)
              : AppColors.surface.withValues(alpha: 0.96),
          borderColor: selected
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.line,
          shadows: [_airyShadow(selected ? AppColors.primary : AppColors.sky)],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.muted,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
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

class _ModuleRecentEventsCard extends StatelessWidget {
  const _ModuleRecentEventsCard({required this.events});

  final List<LifeEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 19),
              SizedBox(width: 8),
              Text(
                '最近动态',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            const Text(
              '今天还没有新记录',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (var index = 0; index < events.length; index++)
              _ModuleRecentEventRow(
                event: events[index],
                showDivider: index != events.length - 1,
              ),
        ],
      ),
    );
  }
}

class _ModuleRecentEventRow extends StatelessWidget {
  const _ModuleRecentEventRow({
    required this.event,
    required this.showDivider,
  });

  final LifeEvent event;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: showDivider ? 10 : 0),
      margin: EdgeInsets.only(bottom: showDivider ? 10 : 0),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(event.icon, color: event.color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
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

String _formatModuleMoney(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toStringAsFixed(0);
  }
  return amount.toStringAsFixed(2);
}

class _AppIconMark extends StatelessWidget {
  const _AppIconMark({this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.waves_rounded, color: Colors.white, size: size * 0.66),
    );
  }
}

class _ModuleListItem extends StatelessWidget {
  const _ModuleListItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = const Color(0xFF9AA8EC),
    this.titleColor = AppColors.ink,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderColor: AppColors.line.withValues(alpha: 0.78),
        shadows: [_airyShadow(iconColor)],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _widgetDirectRecord = true;
  bool _summaryOpensDetail = true;
  bool _dailyReminder = true;
  bool _lowCalorieHint = false;
  String _defaultMeal = '三餐';
  String _themeMode = '跟随系统';

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
      title: '设置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsSectionTitle(
            icon: Icons.widgets_rounded,
            title: '桌面小组件',
          ),
          _SettingsSwitchTile(
            tileKey: const ValueKey('setting_widget_direct_record'),
            icon: Icons.touch_app_rounded,
            title: '快捷按钮直接记录',
            subtitle: '待办、饮食、记账、锻炼',
            value: _widgetDirectRecord,
            onChanged: (value) => setState(() => _widgetDirectRecord = value),
          ),
          _SettingsSwitchTile(
            tileKey: const ValueKey('setting_summary_detail'),
            icon: Icons.open_in_new_rounded,
            title: '摘要进入详情',
            subtitle: '标题和摘要仍打开 App',
            value: _summaryOpensDetail,
            onChanged: (value) => setState(() => _summaryOpensDetail = value),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionTitle(
            icon: Icons.restaurant_rounded,
            title: '饮食记录',
          ),
          _SettingsChoiceCard<String>(
            title: '默认餐次',
            value: _defaultMeal,
            options: const ['早餐', '午餐', '晚餐', '加餐', '三餐'],
            labelBuilder: (value) => value,
            onChanged: (value) => setState(() => _defaultMeal = value),
          ),
          _SettingsSwitchTile(
            tileKey: const ValueKey('setting_low_calorie_hint'),
            icon: Icons.tips_and_updates_rounded,
            title: '轻食提示',
            subtitle: '优先显示低脂高蛋白',
            value: _lowCalorieHint,
            onChanged: (value) => setState(() => _lowCalorieHint = value),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionTitle(
            icon: Icons.palette_rounded,
            title: '显示与提醒',
          ),
          _SettingsChoiceCard<String>(
            title: '外观模式',
            value: _themeMode,
            options: const ['跟随系统', '浅色', '深色'],
            labelBuilder: (value) => value,
            onChanged: (value) => setState(() => _themeMode = value),
          ),
          _SettingsSwitchTile(
            tileKey: const ValueKey('setting_daily_reminder'),
            icon: Icons.notifications_active_rounded,
            title: '每日记录提醒',
            subtitle: '计划、饮食和锻炼',
            value: _dailyReminder,
            onChanged: (value) => setState(() => _dailyReminder = value),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionTitle(
            icon: Icons.help_center_rounded,
            title: '帮助',
          ),
          _SettingsActionTile(
            icon: Icons.quiz_rounded,
            title: 'Q&A',
            subtitle: '健康数据、传感器、小组件常见问题',
            onTap: () => _showQaSheet(context),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionTitle(
            icon: Icons.sync_rounded,
            title: '数据',
          ),
          _SettingsActionTile(
            icon: Icons.widgets_outlined,
            title: '刷新桌面小组件',
            subtitle: '同步当前联动摘要',
            onTap: () => _showSettingsSnack(context, '已请求刷新桌面小组件'),
          ),
          _SettingsActionTile(
            icon: Icons.file_download_rounded,
            title: '导出本地记录',
            subtitle: '计划、财务、饮食、锻炼',
            onTap: () => _showSettingsSnack(context, '已生成本地导出任务'),
          ),
        ],
      ),
    );
  }

  void _showSettingsSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQaSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _QaSheet(),
    );
  }
}

class _QaSheet extends StatelessWidget {
  const _QaSheet();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        '健康模块的数据从哪里来？',
        '步数、能量、基础代谢、睡眠、心率和呼吸频率来自手机系统 Health Connect；计步器、心率和加速度传感器状态来自 Android SensorManager。'
      ),
      ('为什么有些指标显示无系统记录？', 'App 不再使用演示数据。没有授权、系统没有记录、设备没有对应传感器时，会直接显示无系统记录。'),
      (
        '怎样开启真实健康数据？',
        '进入健康页点击授权，按系统提示允许 Health Connect 读取步数、能量、睡眠、心率和呼吸数据，再回到 App 刷新。'
      ),
      ('桌面小组件的健康摘要如何更新？', 'App 成功读取系统健康数据后会写入本机共享摘要，小组件读取同一份状态；没授权时只显示健康待授权。'),
      (
        '数据会上传吗？',
        '当前实现只读取本机系统数据并在本机展示，不接入服务器上传。你可以随时在系统 Health Connect 权限里关闭访问。'
      ),
    ];

    return _InfoSheetFrame(
      title: 'Q&A',
      child: Column(
        children: items
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.muted,
                  title: Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.$2,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
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
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.tileKey,
  });

  final Key? tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: tileKey,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _SettingsIcon(icon: icon),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsChoiceCard<T> extends StatelessWidget {
  const _SettingsChoiceCard({
    required this.title,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = option == value;
              final label = labelBuilder(option);
              return ChoiceChip(
                key: ValueKey('setting_choice_$label'),
                label: Text(label),
                selected: selected,
                selectedColor: AppColors.primarySoft,
                backgroundColor: AppColors.background,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.line,
                ),
                onSelected: (_) => onChanged(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _SettingsIcon(icon: icon),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
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
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}

class _AboutAppSheet extends StatelessWidget {
  const _AboutAppSheet();

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
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
          const _AppIconMark(),
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
    return _InfoSheetFrame(
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
    return _InfoSheetFrame(
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
            const _EmptyCard(
              title: '已收到',
              subtitle: '原型里先做本地反馈状态，后续可以接入邮件、接口或工单系统。',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoSheetFrame extends StatelessWidget {
  const _InfoSheetFrame({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              _IconBubble(
                icon: Icons.close_rounded,
                color: const Color(0xFF9A8FF7),
                onTap: () => Navigator.of(context).pop(),
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
              const SizedBox(width: 42),
            ],
          ),
          const SizedBox(height: 18),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [child],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleSectionTitle extends StatelessWidget {
  const _ModuleSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 19),
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

class _PlanBottomNav extends StatelessWidget {
  const _PlanBottomNav({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.today_rounded, '今日'),
      (Icons.archive_rounded, '待办箱'),
      (Icons.view_week_rounded, '周计划'),
      (Icons.query_stats_rounded, '复盘'),
    ];

    return _CapsuleNav(
      selectedIndex: selectedIndex,
      items: items,
      onChanged: onChanged,
      softCompact: true,
      keyPrefix: 'plan_bottom_nav',
    );
  }
}

class _FinanceBottomNav extends StatelessWidget {
  const _FinanceBottomNav({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.insert_chart_rounded, '总览'),
      (Icons.receipt_long_rounded, '记录'),
      (Icons.account_balance_rounded, '资产'),
    ];

    return _CapsuleNav(
      selectedIndex: selectedIndex,
      items: items,
      onChanged: onChanged,
      softCompact: true,
      keyPrefix: 'finance_bottom_nav',
    );
  }
}

class _ModuleQuickNav extends StatelessWidget {
  const _ModuleQuickNav({
    required this.selected,
    required this.onSwitchModule,
    this.keyPrefix,
    this.glass = false,
  });

  final LifeModule selected;
  final ValueChanged<LifeModule> onSwitchModule;
  final String? keyPrefix;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    return _CapsuleNav(
      selectedIndex: switch (selected) {
        LifeModule.finance => 0,
        LifeModule.plan => 1,
        LifeModule.food => 2,
        LifeModule.workout => 3,
        LifeModule.health => 4,
      },
      items: const [
        (Icons.account_balance_wallet_rounded, '财务'),
        (Icons.event_available_rounded, '计划'),
        (Icons.restaurant_rounded, '饮食'),
        (Icons.fitness_center_rounded, '锻炼'),
        (Icons.monitor_heart_rounded, '健康'),
      ],
      compact: true,
      glass: glass,
      keyPrefix: keyPrefix,
      onChanged: (index) {
        final modules = [
          LifeModule.finance,
          LifeModule.plan,
          LifeModule.food,
          LifeModule.workout,
          LifeModule.health,
        ];
        onSwitchModule(modules[index]);
      },
    );
  }
}

const double _moduleSwitchBarBottomGap = 8;
const double _moduleSwitchBarReservedHeight = 76;

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 18,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColors.surface.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.82),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.sky.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ModuleGlassHeader extends StatelessWidget {
  const _ModuleGlassHeader({
    required this.module,
    required this.title,
    required this.onOpenModules,
    required this.onOpenMore,
  });

  final LifeModule module;
  final String title;
  final VoidCallback onOpenModules;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: _GlassSurface(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          key: const ValueKey('module_glass_header'),
          children: [
            _GlassIconButton(
              icon: Icons.view_sidebar_rounded,
              color: AppColors.primary,
              onTap: onOpenModules,
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  key: ValueKey('module_glass_header_title_${module.name}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            _GlassIconButton(
              icon: Icons.more_horiz_rounded,
              color: AppColors.primary,
              onTap: onOpenMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _HeaderActionPill extends StatelessWidget {
  const _HeaderActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: _GlassSurface(
        borderRadius: 16,
        color: AppColors.surface.withValues(alpha: 0.52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleLinkStrip extends StatelessWidget {
  const _ModuleLinkStrip({
    required this.selected,
    required this.onSwitchModule,
  });

  final LifeModule selected;
  final ValueChanged<LifeModule> onSwitchModule;

  @override
  Widget build(BuildContext context) {
    // 这里是所有主模块共用的联动入口，保证任意模块都能直接跳到其它模块。
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: _GlassSurface(
          borderRadius: 18,
          padding: const EdgeInsets.all(4),
          color: AppColors.surface.withValues(alpha: 0.58),
          child: FittedBox(
            key: const ValueKey('module_link_glass_container'),
            fit: BoxFit.scaleDown,
            child: _ModuleQuickNav(
              selected: selected,
              onSwitchModule: onSwitchModule,
              keyPrefix: 'module_link',
              glass: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _CapsuleNav extends StatelessWidget {
  const _CapsuleNav({
    required this.selectedIndex,
    required this.items,
    required this.onChanged,
    this.compact = false,
    this.softCompact = false,
    this.glass = false,
    this.keyPrefix,
  });

  final int selectedIndex;
  final List<(IconData, String)> items;
  final ValueChanged<int> onChanged;
  final bool compact;
  final bool softCompact;
  final bool glass;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final outerPadding = compact
        ? 4.0
        : softCompact
            ? 4.0
            : 7.0;
    final outerRadius = compact
        ? 16.0
        : softCompact
            ? 14.0
            : 18.0;
    final itemRadius = compact
        ? 12.0
        : softCompact
            ? 11.0
            : 15.0;
    final itemWidth = compact
        ? 42.0
        : softCompact
            ? 50.0
            : 88.0;
    final itemVerticalPadding = compact
        ? 3.0
        : softCompact
            ? 3.0
            : 9.0;
    final iconSize = compact
        ? 17.0
        : softCompact
            ? 15.0
            : 23.0;
    final labelSize = compact
        ? 9.0
        : softCompact
            ? 9.0
            : 12.0;
    final iconLabelGap = compact
        ? 0.0
        : softCompact
            ? 1.0
            : 3.0;

    return Container(
      key: keyPrefix == null ? null : ValueKey('${keyPrefix}_container'),
      padding: EdgeInsets.all(outerPadding),
      decoration: BoxDecoration(
        color: glass
            ? Colors.transparent
            : AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(outerRadius),
        border: glass
            ? null
            : Border.all(color: AppColors.line.withValues(alpha: 0.88)),
        boxShadow: glass
            ? null
            : [
                _airyShadow(AppColors.primary),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = selectedIndex == index;
          return InkWell(
            key: keyPrefix == null ? null : ValueKey('${keyPrefix}_$index'),
            borderRadius: BorderRadius.circular(itemRadius),
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: itemWidth,
              padding: EdgeInsets.symmetric(vertical: itemVerticalPadding),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.sky, AppColors.primary],
                      )
                    : null,
                color: selected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(itemRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.$1,
                    size: iconSize,
                    color: selected ? Colors.white : AppColors.muted,
                  ),
                  SizedBox(height: iconLabelGap),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.muted,
                      fontSize: labelSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        shadows: [_airyShadow(AppColors.sky)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: _airyCardDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          borderColor: color.withValues(alpha: 0.16),
          shadows: [_airyShadow(color)],
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD7DBE8),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
