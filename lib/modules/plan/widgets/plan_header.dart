// 中文注释：计划模块页面组件，负责今日总览、待办箱、周计划和统计视图。

part of '../plan.dart';

/// 计划页顶部栏：模块切换入口和“更多”按钮。
class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    required this.onOpenModules,
    required this.onOpenMore,
  });

  final VoidCallback onOpenModules;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    return ModuleGlassHeader(
      module: LifeModule.plan,
      title: '计划',
      onOpenModules: onOpenModules,
      onOpenMore: onOpenMore,
    );
  }
}

/// 计划页日期工具条：展示当前选中日期，点击后弹出日历选择器。
class _PlanDateToolbar extends StatelessWidget {
  const _PlanDateToolbar({
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  // 打开自定义玻璃风格日历；可选择范围为前后 5 年。
  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDialog<DateTime>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.22),
      builder: (context) => _PlanGlassDatePicker(
        initialDate: selectedDate,
        firstDate: DateTime(now.year - 5, 1, 1),
        lastDate: DateTime(now.year + 5, 12, 31),
      ),
    );
    if (picked == null) {
      return;
    }
    onDateChanged(DateUtils.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    // 按钮文案统一格式化为“xxxx年xx月xx日”。
    final selectedDateText = _formatPlanDate(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('plan_header_date_button'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickDate(context),
            child: GlassSurface(
              borderRadius: 12,
              color: AppColors.surface.withValues(alpha: 0.56),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    key: const ValueKey('plan_header_selected_date'),
                    selectedDateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 玻璃质感的日期选择弹窗，内部仍使用 Flutter 原生 CalendarDatePicker。
class _PlanGlassDatePicker extends StatefulWidget {
  const _PlanGlassDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_PlanGlassDatePicker> createState() => _PlanGlassDatePickerState();
}

/// 日期选择弹窗状态：维护临时选中的日期。
class _PlanGlassDatePickerState extends State<_PlanGlassDatePicker> {
  // 弹窗内临时选中的日期，点“确定”后才回传给调用方。
  late DateTime _draftDate;

  @override
  void initState() {
    super.initState();
    _draftDate = DateUtils.dateOnly(widget.initialDate);
  }

  @override
  Widget build(BuildContext context) {
    // 通过 Theme 覆盖日历的选中色，使其与 App 主色一致。
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: KeyedSubtree(
        key: const ValueKey('plan_glass_date_picker'),
        child: GlassSurface(
          borderRadius: 18,
          color: AppColors.surface.withValues(alpha: 0.62),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formatPlanDate(_draftDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: Colors.transparent,
                          onSurface: AppColors.ink,
                        ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _draftDate,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    onDateChanged: (date) {
                      setState(() => _draftDate = DateUtils.dateOnly(date));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_draftDate),
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
