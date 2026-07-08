// 中文注释：跨模块共享 UI 组件，负责统一卡片、导航、弹层和模块外壳。

part of 'shared.dart';

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _widgetDirectRecord = true;
  bool _summaryOpensDetail = true;
  bool _lowCalorieHint = false;
  String _defaultMeal = '三餐';

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return InfoSheetFrame(
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
            options: const ['早餐', '午餐', '晚餐', '夜宵', '三餐'],
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
          _SettingsSwitchTile(
            tileKey: const ValueKey('setting_daily_reminder'),
            icon: Icons.notifications_active_rounded,
            title: '每日记录提醒',
            subtitle: '计划、饮食和锻炼',
            value: settings.dailyRecordReminderEnabled,
            onChanged: (value) => unawaited(
              _updateDailyReminder(
                context,
                settings,
                value,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionTitle(
            icon: Icons.help_center_rounded,
            title: '帮助',
          ),
          _SettingsActionTile(
            icon: Icons.quiz_rounded,
            title: 'Q&A',
            subtitle: '状态中心、外部数据源、小组件常见问题',
            onTap: () => _showQaSheet(context),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDailyReminder(
    BuildContext context,
    AppSettingsController settings,
    bool enabled,
  ) async {
    final granted = await settings.updateDailyRecordReminder(enabled);
    if (!context.mounted) {
      return;
    }
    final message = enabled
        ? granted
            ? '每日记录提醒已开启'
            : '通知权限未开启，无法提醒'
        : '每日记录提醒已关闭';
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
        '状态中心的数据从哪里来？',
        '状态中心优先使用手动状态记录，并结合饮食摄入、锻炼组数和计划信息生成今日状态。Health Connect 是可选数据源，没有授权也不影响使用。'
      ),
      (
        '为什么不再默认显示步数和心率？',
        '大多数设备不会默认配置 Health Connect。状态中心先保证没有外部权限也能记录和回溯，步数、心率和睡眠会放在外部数据源里作为参考。'
      ),
      (
        '怎样开启真实系统健康数据？',
        '进入状态页底部的外部数据源，按系统提示允许 Health Connect 读取步数、能量、睡眠、心率和呼吸数据，再回到 App 刷新。'
      ),
      ('桌面小组件的状态摘要如何更新？', 'App 会优先展示今日状态记录和模块联动摘要；有系统健康数据时，再补充外部数据源参考。'),
      (
        '数据会上传吗？',
        '当前实现只在本机展示状态记录和系统健康参考数据，不接入服务器上传。你可以随时在系统 Health Connect 权限里关闭访问。'
      ),
    ];

    return InfoSheetFrame(
      title: 'Q&A',
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassSurface(
                  borderRadius: 14,
                  color: AppColors.surface.withValues(alpha: 0.78),
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
    return KeyedSubtree(
      key: tileKey,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassSurface(
          borderRadius: 14,
          color: AppColors.surface.withValues(alpha: 0.78),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(!value),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
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
              ),
            ),
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.78),
        padding: const EdgeInsets.all(14),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.78),
        child: Material(
          type: MaterialType.transparency,
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
