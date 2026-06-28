part of '../../main.dart';

class _QuickRecordSheet extends StatelessWidget {
  const _QuickRecordSheet({required this.onSelect});

  final ValueChanged<WidgetQuickAction> onSelect;

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
      title: '快速记录',
      child: Column(
        children: [
          _QuickRecordTile(
            key: const ValueKey('quick_record_todo'),
            icon: Icons.add_task_rounded,
            color: AppColors.primary,
            title: '加待办',
            subtitle: '写下今天或待办箱里的事',
            onTap: () => onSelect(WidgetQuickAction.addTodo),
          ),
          _QuickRecordTile(
            key: const ValueKey('quick_record_finance'),
            icon: Icons.receipt_long_rounded,
            color: AppColors.financeRed,
            title: '记一笔',
            subtitle: '支出、收入或转账',
            onTap: () => onSelect(WidgetQuickAction.addFinance),
          ),
          _QuickRecordTile(
            key: const ValueKey('quick_record_food'),
            icon: Icons.restaurant_rounded,
            color: AppColors.success,
            title: '记饮食',
            subtitle: '补一餐或常吃食物',
            onTap: () => onSelect(WidgetQuickAction.addFood),
          ),
          _QuickRecordTile(
            key: const ValueKey('quick_record_workout'),
            icon: Icons.fitness_center_rounded,
            color: const Color(0xFF9278F7),
            title: '完成一组',
            subtitle: '进入今日训练动作',
            onTap: () => onSelect(WidgetQuickAction.startWorkout),
          ),
          _QuickRecordTile(
            key: const ValueKey('quick_record_health'),
            icon: Icons.favorite_rounded,
            color: const Color(0xFFFF6F9D),
            title: '看健康',
            subtitle: '打开身体状态仪表盘',
            onTap: () => onSelect(WidgetQuickAction.openHealth),
          ),
        ],
      ),
    );
  }
}

class _QuickRecordTile extends StatelessWidget {
  const _QuickRecordTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 23),
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
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.muted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
