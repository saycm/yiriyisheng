part of 'finance.dart';

class _FinanceRecordSheet extends StatefulWidget {
  const _FinanceRecordSheet({
    required this.record,
    required this.onSave,
  });

  final FinanceRecord? record;
  final ValueChanged<FinanceRecord> onSave;

  @override
  State<_FinanceRecordSheet> createState() => _FinanceRecordSheetState();
}

class _FinanceCategorySpec {
  const _FinanceCategorySpec(this.icon, this.title);

  final IconData icon;
  final String title;
}

class _FinanceRecordSheetState extends State<_FinanceRecordSheet> {
  late final TextEditingController _subtitleController;
  late String _type;
  late _FinanceCategorySpec _category;
  late String _account;
  late String _amountText;
  late DateTime _date;
  double _accumulator = 0;
  String? _operator;

  static const _expenseCategories = [
    _FinanceCategorySpec(Icons.restaurant_rounded, '三餐'),
    _FinanceCategorySpec(Icons.delivery_dining_rounded, '外卖快餐'),
    _FinanceCategorySpec(Icons.local_cafe_rounded, '咖啡'),
    _FinanceCategorySpec(Icons.directions_bus_rounded, '交通'),
    _FinanceCategorySpec(Icons.shopping_bag_rounded, '购物'),
    _FinanceCategorySpec(Icons.phone_iphone_rounded, '数码分期'),
    _FinanceCategorySpec(Icons.movie_rounded, '娱乐'),
    _FinanceCategorySpec(Icons.home_rounded, '居家'),
    _FinanceCategorySpec(Icons.medical_services_rounded, '医疗'),
    _FinanceCategorySpec(Icons.school_rounded, '教育'),
  ];

  static const _incomeCategories = [
    _FinanceCategorySpec(Icons.account_balance_wallet_rounded, '工资'),
    _FinanceCategorySpec(Icons.emoji_events_rounded, '奖金'),
    _FinanceCategorySpec(Icons.savings_rounded, '理财收益'),
    _FinanceCategorySpec(Icons.assignment_return_rounded, '报销'),
    _FinanceCategorySpec(Icons.redeem_rounded, '红包'),
    _FinanceCategorySpec(Icons.work_history_rounded, '兼职'),
  ];

  static const _accounts = ['银行卡', '微信', '支付宝', '现金', '信用卡'];

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _type = record?.type ?? '支出';
    _category = _categoryForRecord(record);
    _account = record?.account ?? '银行卡';
    _subtitleController = TextEditingController(
        text: record?.subtitle == '手动记录' ? '' : record?.subtitle ?? '');
    _amountText = record == null ? '0' : _formatAmountInput(record.amount);
    _date = record?.date ?? DateUtils.dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomInset + 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.record == null ? '记一笔' : '编辑记录',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeTabs(),
                    const SizedBox(height: 6),
                    _buildCategoryStrip(),
                    const SizedBox(height: 6),
                    _buildAccountStrip(),
                    const SizedBox(height: 6),
                    _buildAmountDisplay(),
                    const SizedBox(height: 6),
                    _FinanceTextField(
                      keyValue: 'finance_record_subtitle',
                      controller: _subtitleController,
                      label: '备注',
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 4),
                    _buildAmountKeyboard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FinanceTypeButton(
              buttonKey: const ValueKey('finance_category_expense'),
              label: '支出',
              selected: _type == '支出',
              onTap: () => _setType('支出'),
            ),
          ),
          Expanded(
            child: _FinanceTypeButton(
              buttonKey: const ValueKey('finance_category_income'),
              label: '收入',
              selected: _type == '收入',
              onTap: () => _setType('收入'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _visibleCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _visibleCategories[index];
          final selected = category.title == _category.title;
          return _FinanceCategoryButton(
            buttonKey: ValueKey('finance_category_${category.title}'),
            category: category,
            selected: selected,
            onTap: () => setState(() => _category = category),
          );
        },
      ),
    );
  }

  Widget _buildAccountStrip() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final account = _accounts[index];
          final selected = account == _account;
          return _RangeChip(
            key: ValueKey('finance_account_$account'),
            label: account,
            selected: selected,
            onTap: () => setState(() => _account = account),
          );
        },
      ),
    );
  }

  Widget _buildAmountDisplay() {
    final total = _currentTotal();
    return Container(
      key: const ValueKey('finance_record_amount'),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(_category.icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_category.title} · $_type · $_account',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      '金额',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formatMoney(total),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('finance_amount_clear'),
            tooltip: '清空金额',
            onPressed: _clearAmount,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountKeyboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyWidth = constraints.maxWidth / 4;
        Widget cell(Widget child) => SizedBox(width: keyWidth, child: child);
        return Column(
          children: [
            Row(
              children: [
                cell(_FinanceAmountKey(
                  label: '7',
                  onTap: () => _appendAmount('7'),
                )),
                cell(_FinanceAmountKey(
                  label: '8',
                  onTap: () => _appendAmount('8'),
                )),
                cell(_FinanceAmountKey(
                  label: '9',
                  onTap: () => _appendAmount('9'),
                )),
                cell(_FinanceAmountKey(
                  label: _formatDateKey(_date),
                  keyValue: 'finance_record_date',
                  dense: true,
                  onTap: _pickDate,
                )),
              ],
            ),
            Row(
              children: [
                cell(_FinanceAmountKey(
                  label: '4',
                  onTap: () => _appendAmount('4'),
                )),
                cell(_FinanceAmountKey(
                  label: '5',
                  onTap: () => _appendAmount('5'),
                )),
                cell(_FinanceAmountKey(
                  label: '6',
                  onTap: () => _appendAmount('6'),
                )),
                cell(_FinanceAmountKey(
                  label: '+',
                  keyValue: 'finance_amount_op_add',
                  secondary: true,
                  onTap: () => _applyOperator('+'),
                )),
              ],
            ),
            Row(
              children: [
                cell(_FinanceAmountKey(
                  label: '1',
                  onTap: () => _appendAmount('1'),
                )),
                cell(_FinanceAmountKey(
                  label: '2',
                  onTap: () => _appendAmount('2'),
                )),
                cell(_FinanceAmountKey(
                  label: '3',
                  onTap: () => _appendAmount('3'),
                )),
                cell(_FinanceAmountKey(
                  label: '-',
                  keyValue: 'finance_amount_op_minus',
                  secondary: true,
                  onTap: () => _applyOperator('-'),
                )),
              ],
            ),
            Row(
              children: [
                cell(_FinanceAmountKey(
                  label: '.',
                  keyValue: 'finance_amount_decimal',
                  onTap: () => _appendAmount('.'),
                )),
                cell(_FinanceAmountKey(
                  label: '0',
                  onTap: () => _appendAmount('0'),
                )),
                cell(_FinanceAmountKey(
                  icon: Icons.backspace_outlined,
                  keyValue: 'finance_amount_backspace',
                  onTap: _backspaceAmount,
                )),
                cell(_FinanceAmountKey(
                  label: _operator == null ? '完成' : '=',
                  keyValue: 'save_finance_record',
                  primary: true,
                  onTap: _operator == null ? _save : _finishCalculation,
                )),
              ],
            ),
          ],
        );
      },
    );
  }

  void _save() {
    final amount = _currentTotal().abs();
    if (amount <= 0) {
      return;
    }
    widget.onSave(
      FinanceRecord(
        icon: _category.icon,
        title: _category.title,
        subtitle: _subtitleController.text.trim().isEmpty
            ? '手动记录'
            : _subtitleController.text.trim(),
        amount: amount,
        type: _type,
        date: _date,
        account: _account,
      ),
    );
  }

  List<_FinanceCategorySpec> get _visibleCategories =>
      _type == '收入' ? _incomeCategories : _expenseCategories;

  _FinanceCategorySpec _categoryForRecord(FinanceRecord? record) {
    final categories = (record?.type ?? _type) == '收入'
        ? _incomeCategories
        : _expenseCategories;
    if (record == null) {
      return categories.first;
    }
    for (final category in categories) {
      if (category.title == record.title) {
        return category;
      }
    }
    return _FinanceCategorySpec(
        financeIconForTitle(record.title), record.title);
  }

  void _setType(String type) {
    if (_type == type) {
      return;
    }
    setState(() {
      _type = type;
      final currentStillVisible = _visibleCategories
          .any((category) => category.title == _category.title);
      if (!currentStillVisible) {
        _category = _visibleCategories.first;
      }
    });
  }

  void _appendAmount(String value) {
    if (value == '.' && _amountText.contains('.')) {
      return;
    }
    if (_amountText.contains('.') && value != '.') {
      final decimalCount = _amountText.length - _amountText.indexOf('.') - 1;
      if (decimalCount >= 2) {
        return;
      }
    }
    setState(() {
      if (_amountText == '0' && value != '.') {
        _amountText = value;
      } else {
        _amountText = '$_amountText$value';
      }
    });
    SystemSound.play(SystemSoundType.click);
  }

  void _clearAmount() {
    setState(() {
      _amountText = '0';
      _accumulator = 0;
      _operator = null;
    });
    HapticFeedback.selectionClick();
  }

  void _backspaceAmount() {
    setState(() {
      _amountText = _amountText.length <= 1
          ? '0'
          : _amountText.substring(0, _amountText.length - 1);
    });
    SystemSound.play(SystemSoundType.click);
  }

  void _applyOperator(String operator) {
    final current = double.tryParse(_amountText) ?? 0;
    setState(() {
      if (_operator == '+') {
        _accumulator += current;
      } else if (_operator == '-') {
        _accumulator -= current;
      } else {
        _accumulator = current;
      }
      _operator = operator;
      _amountText = '0';
    });
    HapticFeedback.selectionClick();
  }

  void _finishCalculation() {
    final current = double.tryParse(_amountText) ?? 0;
    final total = _operator == '+'
        ? _accumulator + current
        : _operator == '-'
            ? _accumulator - current
            : current;
    setState(() {
      _amountText = _formatAmountInput(total.abs());
      _accumulator = 0;
      _operator = null;
    });
    HapticFeedback.selectionClick();
  }

  double _currentTotal() {
    final current = double.tryParse(_amountText) ?? 0;
    if (_operator == '+') {
      return _accumulator + current;
    }
    if (_operator == '-') {
      return _accumulator - current;
    }
    return current;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  String _formatAmountInput(double amount) {
    final fixed = amount.toStringAsFixed(2);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatDateKey(DateTime date) => '${date.month}/${date.day}';
}

class _FinanceTypeButton extends StatelessWidget {
  const _FinanceTypeButton({
    required this.buttonKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FinanceCategoryButton extends StatelessWidget {
  const _FinanceCategoryButton({
    required this.buttonKey,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final _FinanceCategorySpec category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 62,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              color: selected ? AppColors.primary : AppColors.muted,
              size: 18,
            ),
            const SizedBox(height: 3),
            Text(
              category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceAmountKey extends StatelessWidget {
  const _FinanceAmountKey({
    this.label,
    this.icon,
    this.keyValue,
    this.primary = false,
    this.secondary = false,
    this.dense = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final String? keyValue;
  final bool primary;
  final bool secondary;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = primary
        ? AppColors.primary
        : secondary
            ? AppColors.primarySoft
            : AppColors.background;
    final foreground = primary
        ? Colors.white
        : secondary
            ? AppColors.primary
            : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: ValueKey(keyValue ?? 'finance_amount_key_$label'),
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 34,
            child: Center(
              child: icon == null
                  ? Text(
                      label!,
                      style: TextStyle(
                        color: foreground,
                        fontSize: dense ? 12 : 17,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : Icon(icon, color: foreground, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}
