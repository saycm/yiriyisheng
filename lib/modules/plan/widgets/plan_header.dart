part of '../../../main.dart';

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    required this.onOpenModules,
    required this.onOpenMore,
  });

  final VoidCallback onOpenModules;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    return _ModuleGlassHeader(
      module: LifeModule.plan,
      title: '计划',
      onOpenModules: onOpenModules,
      onOpenMore: onOpenMore,
    );
  }
}

class _PlanDateToolbar extends StatelessWidget {
  const _PlanDateToolbar({
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

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
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: _GlassSurface(
        borderRadius: 16,
        color: AppColors.surface.withValues(alpha: 0.52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            InkWell(
              key: const ValueKey('plan_header_date_button'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => _pickDate(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.72)),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                key: const ValueKey('plan_header_selected_date'),
                selectedDateText,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
