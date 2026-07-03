part of 'finance.dart';

class _NetAssetCard extends StatelessWidget {
  const _NetAssetCard({
    required this.accounts,
    required this.income,
    required this.expense,
    required this.onOpenAssets,
    required this.onAddRecord,
  });

  final List<_FinanceAccountSnapshot> accounts;
  final double income;
  final double expense;
  final VoidCallback onOpenAssets;
  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    final cashflow = income - expense;
    final netAsset = accounts.fold<double>(
      0,
      (total, account) => total + account.balance,
    );
    final visibleAccounts = accounts.take(3).toList();
    return Container(
      key: const ValueKey('finance_workspace_card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '资产工作台',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '账户、收支、预算一起看',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${accounts.length} 个账户',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF172033), Color(0xFF2C3D73)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '净资产',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _signedMoney(netAsset),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FinanceWorkspaceMetric(
                        label: '收入',
                        value: formatMoney(income),
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FinanceWorkspaceMetric(
                        label: '支出',
                        value: formatMoney(expense),
                        color: AppColors.financeRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FinanceWorkspaceMetric(
                        label: '现金流',
                        value: _signedMoney(cashflow),
                        color: cashflow >= 0
                            ? AppColors.primary
                            : AppColors.financeRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FinanceWorkspaceAction(
                  icon: Icons.add_card_rounded,
                  title: '记一笔',
                  subtitle: '收入 / 支出',
                  color: AppColors.primary,
                  onTap: onAddRecord,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FinanceWorkspaceAction(
                  icon: Icons.account_balance_rounded,
                  title: '查看资产详情',
                  subtitle: '资产明细',
                  color: AppColors.success,
                  onTap: onOpenAssets,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final account in visibleAccounts)
            _FinanceWorkspaceAccountRow(account: account),
        ],
      ),
    );
  }
}

class _FinanceWorkspaceMetric extends StatelessWidget {
  const _FinanceWorkspaceMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final displayColor = color == AppColors.primary ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: displayColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceWorkspaceAction extends StatelessWidget {
  const _FinanceWorkspaceAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = color == AppColors.success
        ? const Color(0xFF16865E)
        : AppColors.primary;
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceWorkspaceAccountRow extends StatelessWidget {
  const _FinanceWorkspaceAccountRow({required this.account});

  final _FinanceAccountSnapshot account;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: account.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(account.icon, color: account.color, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              account.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            _signedMoney(account.balance),
            style: TextStyle(
              color: account.balance < 0 ? AppColors.financeRed : AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
