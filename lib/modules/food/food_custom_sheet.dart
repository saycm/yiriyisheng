part of 'food.dart';

class _CustomFoodSheet extends StatefulWidget {
  const _CustomFoodSheet({
    required this.initialName,
    required this.initialCategory,
    required this.onSave,
  });

  final String initialName;
  final String initialCategory;
  final void Function(String name, int calorie, String unit, String group)
      onSave;

  @override
  State<_CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends State<_CustomFoodSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _calorieController;
  late final TextEditingController _unitController;
  late String _group;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _calorieController = TextEditingController(text: '120');
    _unitController = TextEditingController(text: '1 份');
    _group = _customFoodCategoryLabels.contains(widget.initialCategory)
        ? widget.initialCategory
        : '自定义';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '自定义食物',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              SheetTextField(
                keyName: 'custom_food_name',
                controller: _nameController,
                label: '食物名称',
                hint: '例如：燕麦酸奶',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SheetTextField(
                      keyName: 'custom_food_calorie',
                      controller: _calorieController,
                      label: '热量',
                      hint: '120',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SheetTextField(
                      keyName: 'custom_food_unit',
                      controller: _unitController,
                      label: '单位',
                      hint: '1 份',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '分类',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _customFoodCategoryLabels.map((group) {
                  final selected = _group == group;
                  return ChoiceChip(
                    key: ValueKey('custom_food_group_$group'),
                    label: Text(group),
                    selected: selected,
                    onSelected: (_) => setState(() => _group = group),
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primary : AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: const ValueKey('save_custom_food_button'),
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();
    final calorie = int.tryParse(_calorieController.text.trim());
    if (name.isEmpty || unit.isEmpty || calorie == null || calorie <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写有效的食物名称、热量和单位'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSave(name, calorie, unit, _group);
  }
}
