part of '../../../main.dart';

class _PlanMoreSheet extends StatelessWidget {
  const _PlanMoreSheet({
    required this.activeFilter,
    required this.completedCount,
    required this.onSelectFilter,
    required this.onClearCompleted,
  });

  final String activeFilter;
  final int completedCount;
  final ValueChanged<String> onSelectFilter;
  final VoidCallback onClearCompleted;

  @override
  Widget build(BuildContext context) {
    final categories = [
      '全部',
      ..._todoCategoryOptions().map((category) => category.$1),
    ];

    return _InfoSheetFrame(
      title: '待办选项',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '筛选类别',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories.map((category) {
              return ChoiceChip(
                key: ValueKey('plan_filter_$category'),
                label: Text(category),
                selected: activeFilter == category,
                selectedColor: AppColors.primarySoft,
                backgroundColor: AppColors.surface,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: activeFilter == category
                      ? AppColors.primary
                      : AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: activeFilter == category
                      ? AppColors.primary
                      : Colors.transparent,
                ),
                onSelected: (_) => onSelectFilter(category),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: completedCount == 0 ? null : onClearCompleted,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.financeRed,
                side: BorderSide(
                  color: completedCount == 0
                      ? AppColors.muted.withValues(alpha: 0.24)
                      : AppColors.financeRed.withValues(alpha: 0.32),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.cleaning_services_rounded, size: 19),
              label: Text(
                '清理已完成 ($completedCount)',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
