// 中文注释：计划模块弹层组件，负责待办新增、筛选和快捷收集。

part of '../plan.dart';

void _showPlanTodoEditorSheet({
  required BuildContext context,
  required DateTime today,
  required ValueChanged<TodoItem> onSave,
}) {
  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final customCategoryController = TextEditingController();
  final categories = _todoCategoryOptions();
  var selectedCategory = categories.first;
  var selectedPriority = TodoPriority.shouldDo;
  var selectedStatus = TodoStatus.notStarted;
  DateTime? selectedDate = today;
  var selectedRepeat = TodoRepeatRule.none;
  final linkedModules = <TodoLinkedModule>{};

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.18),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
            ),
            child: KeyedSubtree(
              key: const ValueKey('plan_todo_editor_glass_panel'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.76),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.74),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(sheetContext).copyWith(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(
                            horizontal: -2,
                            vertical: -2,
                          ),
                          chipTheme: Theme.of(sheetContext).chipTheme.copyWith(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 0,
                                ),
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                labelStyle: _todoEditorChipLabelStyle(
                                  selected: false,
                                ),
                                secondaryLabelStyle: _todoEditorChipLabelStyle(
                                  selected: true,
                                ),
                              ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SheetHandle(),
                              const SizedBox(height: 14),
                              const Text(
                                '新增待办',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: titleController,
                                autofocus: false,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: _todoEditorInputDecoration(
                                  '标题，例如：还信用卡',
                                ),
                              ),
                              const SizedBox(height: 12),
                              const _PlanFieldLabel('分类'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: categories.map((category) {
                                  final selected =
                                      selectedCategory.$1 == category.$1;
                                  return ChoiceChip(
                                    label: Text(category.$1),
                                    selected: selected,
                                    selectedColor: _todoEditorChipFill(
                                      selected: true,
                                      color: category.$2,
                                    ),
                                    backgroundColor: _todoEditorChipFill(
                                      selected: false,
                                      color: category.$2,
                                    ),
                                    showCheckmark: false,
                                    labelStyle: _todoEditorChipLabelStyle(
                                      selected: selected,
                                      selectedColor: category.$2,
                                    ),
                                    side: _todoEditorChipSide(
                                      selected: selected,
                                      color: category.$2,
                                    ),
                                    onSelected: (_) {
                                      setSheetState(
                                        () => selectedCategory = category,
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                              if (selectedCategory.$1 == '自定义') ...[
                                const SizedBox(height: 10),
                                TextField(
                                  controller: customCategoryController,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration:
                                      _todoEditorInputDecoration('自定义分类名称'),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const _PlanFieldLabel('优先级'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: TodoPriority.values.map((priority) {
                                  final selected = selectedPriority == priority;
                                  return ChoiceChip(
                                    avatar: Icon(
                                      priority.icon,
                                      size: 15,
                                      color: _todoEditorChipIconColor(
                                        selected: selected,
                                        selectedColor: priority.color,
                                      ),
                                    ),
                                    label: Text(priority.label),
                                    selected: selected,
                                    selectedColor: _todoEditorChipFill(
                                      selected: true,
                                      color: priority.color,
                                    ),
                                    backgroundColor: _todoEditorChipFill(
                                      selected: false,
                                      color: priority.color,
                                    ),
                                    showCheckmark: false,
                                    labelStyle: _todoEditorChipLabelStyle(
                                      selected: selected,
                                      selectedColor: priority.color,
                                    ),
                                    side: _todoEditorChipSide(
                                      selected: selected,
                                      color: priority.color,
                                    ),
                                    onSelected: (_) {
                                      setSheetState(
                                        () => selectedPriority = priority,
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const _PlanFieldLabel('日期'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('今天'),
                                    selected: DateUtils.isSameDay(
                                      selectedDate,
                                      today,
                                    ),
                                    selectedColor: _todoEditorChipFill(
                                      selected: true,
                                      color: AppColors.primary,
                                    ),
                                    backgroundColor: _todoEditorChipFill(
                                      selected: false,
                                      color: AppColors.primary,
                                    ),
                                    showCheckmark: false,
                                    labelStyle: _todoEditorChipLabelStyle(
                                      selected: DateUtils.isSameDay(
                                        selectedDate,
                                        today,
                                      ),
                                    ),
                                    side: _todoEditorChipSide(
                                      selected: DateUtils.isSameDay(
                                        selectedDate,
                                        today,
                                      ),
                                      color: AppColors.primary,
                                    ),
                                    onSelected: (_) {
                                      setSheetState(
                                        () => selectedDate = today,
                                      );
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('明天'),
                                    selected: DateUtils.isSameDay(
                                      selectedDate,
                                      today.add(const Duration(days: 1)),
                                    ),
                                    selectedColor: _todoEditorChipFill(
                                      selected: true,
                                      color: AppColors.primary,
                                    ),
                                    backgroundColor: _todoEditorChipFill(
                                      selected: false,
                                      color: AppColors.primary,
                                    ),
                                    showCheckmark: false,
                                    labelStyle: _todoEditorChipLabelStyle(
                                      selected: DateUtils.isSameDay(
                                        selectedDate,
                                        today.add(const Duration(days: 1)),
                                      ),
                                    ),
                                    side: _todoEditorChipSide(
                                      selected: DateUtils.isSameDay(
                                        selectedDate,
                                        today.add(const Duration(days: 1)),
                                      ),
                                      color: AppColors.primary,
                                    ),
                                    onSelected: (_) {
                                      setSheetState(
                                        () => selectedDate = today.add(
                                          const Duration(days: 1),
                                        ),
                                      );
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('无日期'),
                                    selected: selectedDate == null,
                                    selectedColor: _todoEditorChipFill(
                                      selected: true,
                                      color: AppColors.primary,
                                    ),
                                    backgroundColor: _todoEditorChipFill(
                                      selected: false,
                                      color: AppColors.primary,
                                    ),
                                    showCheckmark: false,
                                    labelStyle: _todoEditorChipLabelStyle(
                                      selected: selectedDate == null,
                                    ),
                                    side: _todoEditorChipSide(
                                      selected: selectedDate == null,
                                      color: AppColors.primary,
                                    ),
                                    onSelected: (_) {
                                      setSheetState(
                                        () => selectedDate = null,
                                      );
                                    },
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: sheetContext,
                                        initialDate: selectedDate ?? today,
                                        firstDate: today.subtract(
                                          const Duration(days: 365),
                                        ),
                                        lastDate: today.add(
                                          const Duration(days: 365 * 2),
                                        ),
                                      );
                                      if (picked == null) {
                                        return;
                                      }
                                      setSheetState(
                                        () => selectedDate =
                                            DateUtils.dateOnly(picked),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      backgroundColor: AppColors.surface
                                          .withValues(alpha: 0.62),
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.78,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      minimumSize: const Size(0, 34),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      selectedDate == null
                                          ? '选择日期'
                                          : _formatPlanDate(selectedDate),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const _PlanFieldLabel('状态'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  TodoStatus.notStarted,
                                  TodoStatus.inProgress,
                                ].map((status) {
                                  final selected = selectedStatus == status;
                                  return ChoiceChip(
                                    avatar: Icon(
                                      status.icon,
                                      size: 15,
                                      color: _todoEditorChipIconColor(
                                        selected: selected,
                                      ),
                                    ),
                                    label: Text(status.label),
                                    selected: selected,
                                    selectedColor: _todoEditorChipFill(
                                      selected: true,
                                      color: AppColors.primary,
                                    ),
                                    backgroundColor: _todoEditorChipFill(
                                      selected: false,
                                      color: AppColors.primary,
                                    ),
                                    showCheckmark: false,
                                    labelStyle: _todoEditorChipLabelStyle(
                                      selected: selected,
                                    ),
                                    side: _todoEditorChipSide(
                                      selected: selected,
                                      color: AppColors.primary,
                                    ),
                                    onSelected: (_) {
                                      setSheetState(
                                        () => selectedStatus = status,
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const _PlanFieldLabel('重复'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: TodoRepeatRule.values.map((rule) {
                                  final selected = selectedRepeat == rule;
                                  return ChoiceChip(
                                    label: Text(rule.label),
                                    selected: selected,
                                    selectedColor: _todoEditorChipFill(
                                      selected: true,
                                      color: AppColors.primary,
                                    ),
                                    backgroundColor: _todoEditorChipFill(
                                      selected: false,
                                      color: AppColors.primary,
                                    ),
                                    showCheckmark: false,
                                    labelStyle: _todoEditorChipLabelStyle(
                                      selected: selected,
                                    ),
                                    side: _todoEditorChipSide(
                                      selected: selected,
                                      color: AppColors.primary,
                                    ),
                                    onSelected: (_) {
                                      setSheetState(
                                        () => selectedRepeat = rule,
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const _PlanFieldLabel('任务联动'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: TodoLinkedModule.values.map((module) {
                                  final selected =
                                      linkedModules.contains(module);
                                  return FilterChip(
                                    avatar: Icon(
                                      module.icon,
                                      size: 15,
                                      color: _todoEditorChipIconColor(
                                        selected: selected,
                                        selectedColor: module.color,
                                      ),
                                    ),
                                    label: Text(module.label),
                                    selected: selected,
                                    selectedColor: _todoEditorChipFill(
                                      selected: true,
                                      color: module.color,
                                    ),
                                    backgroundColor: _todoEditorChipFill(
                                      selected: false,
                                      color: module.color,
                                    ),
                                    showCheckmark: false,
                                    labelStyle: _todoEditorChipLabelStyle(
                                      selected: selected,
                                      selectedColor: module.color,
                                    ),
                                    side: _todoEditorChipSide(
                                      selected: selected,
                                      color: module.color,
                                    ),
                                    onSelected: (checked) {
                                      setSheetState(() {
                                        if (checked) {
                                          linkedModules.add(module);
                                        } else {
                                          linkedModules.remove(module);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: noteController,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                minLines: 1,
                                maxLines: 2,
                                decoration: _todoEditorInputDecoration(
                                  '备注，可写触发条件或补充说明',
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: FilledButton(
                                  onPressed: () {
                                    final title = titleController.text.trim();
                                    if (title.isEmpty) {
                                      return;
                                    }
                                    final customCategory =
                                        customCategoryController.text.trim();
                                    final category =
                                        selectedCategory.$1 == '自定义' &&
                                                customCategory.isNotEmpty
                                            ? customCategory
                                            : selectedCategory.$1;
                                    onSave(
                                      TodoItem(
                                        title: title,
                                        category: category,
                                        color: todoColorForCategory(category),
                                        priority: selectedPriority,
                                        status: selectedStatus,
                                        dueDate: selectedDate,
                                        note: noteController.text.trim(),
                                        repeatRule: selectedRepeat,
                                        linkedModules: linkedModules.toList(),
                                      ),
                                    );
                                    Navigator.of(sheetContext).pop();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.zero,
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('保存'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

const Color _todoEditorChipInk = Color(0xFF46536B);
const Color _todoEditorHintInk = Color(0xFF657188);

InputDecoration _todoEditorInputDecoration(String hint) {
  final enabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.76)),
  );

  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
      color: AppColors.primary.withValues(alpha: 0.72),
      width: 1.2,
    ),
  );

  return _planInputDecoration(hint).copyWith(
    hintStyle: const TextStyle(
      color: _todoEditorHintInk,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    fillColor: AppColors.surface.withValues(alpha: 0.66),
    enabledBorder: enabledBorder,
    focusedBorder: focusedBorder,
  );
}

Color _todoEditorChipFill({
  required bool selected,
  required Color color,
}) {
  return selected
      ? color.withValues(alpha: 0.14)
      : AppColors.surface.withValues(alpha: 0.62);
}

BorderSide _todoEditorChipSide({
  required bool selected,
  required Color color,
}) {
  return BorderSide(
    color: selected
        ? color.withValues(alpha: 0.56)
        : Colors.white.withValues(alpha: 0.82),
  );
}

Color _todoEditorChipIconColor({
  required bool selected,
  Color selectedColor = AppColors.primary,
}) {
  return selected ? selectedColor : _todoEditorChipInk.withValues(alpha: 0.86);
}

TextStyle _todoEditorChipLabelStyle({
  required bool selected,
  Color selectedColor = AppColors.primary,
}) {
  return TextStyle(
    color: selected ? selectedColor : _todoEditorChipInk,
    fontSize: 12,
    fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
  );
}

class _PlanFieldLabel extends StatelessWidget {
  const _PlanFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
