part of 'finance.dart';

class _FinanceOverviewView extends StatelessWidget {
  const _FinanceOverviewView({
    required this.showExpense,
    required this.trendRange,
    required this.records,
    required this.onOpenAssets,
    required this.onAddRecord,
    required this.onToggleTrend,
    required this.onChangeTrendRange,
  });

  final bool showExpense;
  final String trendRange;
  final List<FinanceRecord> records;
  final VoidCallback onOpenAssets;
  final VoidCallback onAddRecord;
  final ValueChanged<bool> onToggleTrend;
  final ValueChanged<String> onChangeTrendRange;

  @override
  Widget build(BuildContext context) {
    final income = _financeTotal(records, '收入');
    final expense = _financeTotal(records, '支出');
    final accounts = _financeAccounts(records);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          18, 0, 18, moduleSwitchBarReservedHeight + 24),
      children: [
        _FinanceHealthCard(records: records),
        const SizedBox(height: 14),
        _NetAssetCard(
          accounts: accounts,
          income: income,
          expense: expense,
          onOpenAssets: onOpenAssets,
          onAddRecord: onAddRecord,
        ),
        const SizedBox(height: 14),
        _FinanceBudgetInsightCard(records: records),
        const SizedBox(height: 14),
        _TrendCard(
          showExpense: showExpense,
          trendRange: trendRange,
          onToggleTrend: onToggleTrend,
          onChangeRange: onChangeTrendRange,
        ),
      ],
    );
  }
}
