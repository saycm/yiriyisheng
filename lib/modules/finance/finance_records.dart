// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

class _FinanceRecordsView extends StatefulWidget {
  const _FinanceRecordsView({
    required this.records,
    required this.onAddRecord,
    required this.onEditRecord,
  });

  final List<FinanceRecord> records;
  final ValueChanged<FinanceRecord> onAddRecord;
  final void Function(FinanceRecord oldRecord, FinanceRecord newRecord)
      onEditRecord;

  @override
  State<_FinanceRecordsView> createState() => _FinanceRecordsViewState();
}

class _FinanceRecordsViewState extends State<_FinanceRecordsView> {
  String _filter = '全部';

  @override
  Widget build(BuildContext context) {
    final visibleRecords = _filter == '全部'
        ? widget.records
        : widget.records.where((record) => record.type == _filter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        _FinanceMonthSummary(records: widget.records),
        const SizedBox(height: 14),
        Row(
          children: [
            _RangeChip(
              key: const ValueKey('finance_filter_all'),
              label: '全部',
              selected: _filter == '全部',
              onTap: () => setState(() => _filter = '全部'),
            ),
            const SizedBox(width: 8),
            _RangeChip(
              key: const ValueKey('finance_filter_expense'),
              label: '支出',
              selected: _filter == '支出',
              onTap: () => setState(() => _filter = '支出'),
            ),
            const SizedBox(width: 8),
            _RangeChip(
              key: const ValueKey('finance_filter_income'),
              label: '收入',
              selected: _filter == '收入',
              onTap: () => setState(() => _filter = '收入'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...visibleRecords.map(
          (record) => _FinanceRecordTile(
            record: record,
            onTap: () => _openRecordSheet(record: record),
          ),
        ),
      ],
    );
  }

  void _openRecordSheet({FinanceRecord? record}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FinanceRecordSheet(
          record: record,
          onSave: (newRecord) {
            Navigator.of(context).pop();
            if (record == null) {
              widget.onAddRecord(newRecord);
            } else {
              widget.onEditRecord(record, newRecord);
            }
          },
        );
      },
    );
  }
}

class _FinanceMonthSummary extends StatelessWidget {
  const _FinanceMonthSummary({required this.records});

  final List<FinanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final income = _financeTotal(records, '收入');
    final expense = _financeTotal(records, '支出');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SmallFinanceStat(
              title: '收入',
              value: formatMoney(income),
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SmallFinanceStat(
              title: '支出',
              value: formatMoney(expense),
              color: AppColors.financeRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SmallFinanceStat(
              title: '结余',
              value: formatMoney(income - expense),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallFinanceStat extends StatelessWidget {
  const _SmallFinanceStat({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FinanceRecordTile extends StatelessWidget {
  const _FinanceRecordTile({
    required this.record,
    required this.onTap,
  });

  final FinanceRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: record.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(record.icon, color: record.color, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _FinanceAccountBadge(account: record.account),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              record.displayAmount,
              style: TextStyle(
                color: record.color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceAccountBadge extends StatelessWidget {
  const _FinanceAccountBadge({required this.account});

  final String account;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        account,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
