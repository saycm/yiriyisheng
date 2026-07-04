// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

class _FinanceBudgetInsightCard extends StatelessWidget {
  const _FinanceBudgetInsightCard({required this.records});

  final List<FinanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final categories = _categoryBudgets(records);
    final fixedCosts = _fixedCostRecords(records);
    final alerts = _budgetAlerts(categories);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '分类预算',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            const Text(
              '还没有支出记录',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...categories.map((budget) => _CategoryBudgetRow(budget: budget)),
          const SizedBox(height: 16),
          const _FinanceSectionTitle(
            icon: Icons.repeat_rounded,
            title: '固定支出',
          ),
          const SizedBox(height: 10),
          if (fixedCosts.isEmpty)
            const Text(
              '暂未识别固定支出',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...fixedCosts.map((record) => _FixedCostRow(record: record)),
          const SizedBox(height: 16),
          const _FinanceSectionTitle(
            icon: Icons.warning_amber_rounded,
            title: '异常提醒',
          ),
          const SizedBox(height: 10),
          if (alerts.isEmpty)
            const Text(
              '预算使用正常',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...alerts.map((alert) => _BudgetAlertRow(alert: alert)),
        ],
      ),
    );
  }
}

class _CategoryBudgetRow extends StatelessWidget {
  const _CategoryBudgetRow({required this.budget});

  final _CategoryBudget budget;

  @override
  Widget build(BuildContext context) {
    final progress = budget.used / budget.limit;
    final color = progress >= 0.8 ? AppColors.financeRed : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              financeIconForTitle(budget.title),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        budget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '已用 ${formatMoney(budget.used)} / ${formatMoney(budget.limit)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.background,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedCostRow extends StatelessWidget {
  const _FixedCostRow({required this.record});

  final FinanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(record.icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subtitle.isEmpty ? record.title : record.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '每月预计 ${formatMoney(record.amount)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetAlertRow extends StatelessWidget {
  const _BudgetAlertRow({required this.alert});

  final _BudgetAlert alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.financeRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.financeRed.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.financeRed,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.detail,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceSectionTitle extends StatelessWidget {
  const _FinanceSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CategoryBudget {
  const _CategoryBudget({
    required this.title,
    required this.used,
    required this.limit,
  });

  final String title;
  final double used;
  final double limit;
}

class _BudgetAlert {
  const _BudgetAlert({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}

List<_CategoryBudget> _categoryBudgets(List<FinanceRecord> records) {
  const limits = {
    '三餐': 1000.0,
    '外卖快餐': 1000.0,
    '咖啡': 300.0,
    '交通': 500.0,
    '购物': 1200.0,
    '数码分期': 600.0,
    '娱乐': 500.0,
    '居家': 800.0,
    '医疗': 800.0,
    '教育': 600.0,
  };
  final usedByTitle = <String, double>{};
  for (final record in records.where((record) => record.type == '支出')) {
    usedByTitle.update(record.title, (value) => value + record.amount,
        ifAbsent: () => record.amount);
  }
  final budgets = usedByTitle.entries.map((entry) {
    return _CategoryBudget(
      title: entry.key,
      used: entry.value,
      limit: limits[entry.key] ?? 500.0,
    );
  }).toList()
    ..sort((a, b) => (b.used / b.limit).compareTo(a.used / a.limit));
  return budgets.take(4).toList();
}

List<FinanceRecord> _fixedCostRecords(List<FinanceRecord> records) {
  const keywords = ['分期', '还款', '房租', '会员', '保险', '订阅'];
  return records.where((record) {
    if (record.type != '支出') {
      return false;
    }
    final text = '${record.title}${record.subtitle}';
    return keywords.any(text.contains);
  }).toList();
}

List<_BudgetAlert> _budgetAlerts(List<_CategoryBudget> budgets) {
  return budgets.where((budget) => budget.used / budget.limit >= 0.8).map(
    (budget) {
      final percent = (budget.used / budget.limit * 100).round();
      return _BudgetAlert(
        title: '${budget.title}接近分类预算',
        detail:
            '已使用 $percent%，剩余 ${formatMoney(math.max(0, budget.limit - budget.used))}',
      );
    },
  ).toList();
}
