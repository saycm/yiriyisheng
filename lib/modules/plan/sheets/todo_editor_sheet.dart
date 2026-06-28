part of '../../../main.dart';

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
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Theme(
                data: Theme.of(sheetContext).copyWith(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity:
                      const VisualDensity(horizontal: -2, vertical: -2),
                  chipTheme: Theme.of(sheetContext).chipTheme.copyWith(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 0,
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        secondaryLabelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SheetHandle(),
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
                        autofocus: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: _planInputDecoration('标题，例如：还信用卡'),
                      ),
                      const SizedBox(height: 12),
                      const _PlanFieldLabel('分类'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((category) {
                          final selected = selectedCategory.$1 == category.$1;
                          return ChoiceChip(
                            label: Text(category.$1),
                            selected: selected,
                            selectedColor: category.$2.withValues(alpha: 0.16),
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: selected ? category.$2 : AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                            side: BorderSide(
                              color:
                                  selected ? category.$2 : Colors.transparent,
                            ),
                            onSelected: (_) {
                              setSheetState(() => selectedCategory = category);
                            },
                          );
                        }).toList(),
                      ),
                      if (selectedCategory.$1 == '自定义') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: customCategoryController,
                          style: const TextStyle(fontSize: 14),
                          decoration: _planInputDecoration('自定义分类名称'),
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
                              color:
                                  selected ? priority.color : AppColors.muted,
                            ),
                            label: Text(priority.label),
                            selected: selected,
                            selectedColor:
                                priority.color.withValues(alpha: 0.13),
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color:
                                  selected ? priority.color : AppColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? priority.color
                                  : Colors.transparent,
                            ),
                            onSelected: (_) {
                              setSheetState(() => selectedPriority = priority);
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
                            selected: DateUtils.isSameDay(selectedDate, today),
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            onSelected: (_) {
                              setSheetState(() => selectedDate = today);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('明天'),
                            selected: DateUtils.isSameDay(
                              selectedDate,
                              today.add(const Duration(days: 1)),
                            ),
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            onSelected: (_) {
                              setSheetState(
                                () => selectedDate =
                                    today.add(const Duration(days: 1)),
                              );
                            },
                          ),
                          ChoiceChip(
                            label: const Text('无日期'),
                            selected: selectedDate == null,
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            onSelected: (_) {
                              setSheetState(() => selectedDate = null);
                            },
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: sheetContext,
                                initialDate: selectedDate ?? today,
                                firstDate:
                                    today.subtract(const Duration(days: 365)),
                                lastDate:
                                    today.add(const Duration(days: 365 * 2)),
                              );
                              if (picked == null) {
                                return;
                              }
                              setSheetState(
                                () => selectedDate = DateUtils.dateOnly(picked),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.line),
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
                                fontWeight: FontWeight.w700,
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
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                            label: Text(status.label),
                            selected: selected,
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            onSelected: (_) {
                              setSheetState(() => selectedStatus = status);
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
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                            onSelected: (_) {
                              setSheetState(() => selectedRepeat = rule);
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
                          final selected = linkedModules.contains(module);
                          return FilterChip(
                            avatar: Icon(
                              module.icon,
                              size: 15,
                              color: selected ? module.color : AppColors.muted,
                            ),
                            label: Text(module.label),
                            selected: selected,
                            selectedColor: module.color.withValues(alpha: 0.13),
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: selected ? module.color : AppColors.muted,
                              fontWeight: FontWeight.w800,
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
                        style: const TextStyle(fontSize: 14),
                        minLines: 1,
                        maxLines: 2,
                        decoration: _planInputDecoration('备注，可写触发条件或补充说明'),
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
                            final category = selectedCategory.$1 == '自定义' &&
                                    customCategory.isNotEmpty
                                ? customCategory
                                : selectedCategory.$1;
                            onSave(
                              TodoItem(
                                title: title,
                                category: category,
                                color: _todoColorForCategory(category),
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
          );
        },
      );
    },
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
