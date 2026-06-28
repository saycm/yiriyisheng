part of '../../../main.dart';

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    required this.selectedDate,
    required this.onDateChanged,
    required this.onOpenModules,
    required this.onOpenMore,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onOpenModules;
  final VoidCallback onOpenMore;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked == null) {
      return;
    }
    onDateChanged(DateUtils.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final monthText = _formatPlanMonth(selectedDate);
    final selectedDateText = _formatPlanDate(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: _airyCardDecoration(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderColor: AppColors.line.withValues(alpha: 0.82),
              shadows: [_airyShadow(AppColors.sky)],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _IconBubble(
                      icon: Icons.view_sidebar_rounded,
                      color: AppColors.lavender,
                      onTap: onOpenModules,
                    ),
                    Expanded(
                      child: Center(
                        child: InkWell(
                          key: const ValueKey('plan_header_date_button'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _pickDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft.withValues(
                                alpha: 0.82,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  monthText,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.expand_more_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _IconBubble(
                      icon: Icons.more_horiz_rounded,
                      color: AppColors.primary,
                      onTap: onOpenMore,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  key: const ValueKey('plan_header_selected_date'),
                  selectedDateText,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
