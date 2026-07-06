// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

class _FinanceAccountSnapshot {
  const _FinanceAccountSnapshot({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.openingBalance,
    required this.balance,
  });

  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double openingBalance;
  final double balance;
}

List<_FinanceAccountSnapshot> _financeAccounts(List<FinanceRecord> records) {
  // 账户余额只从真实账单推导；没有用户记录时保持 0，避免展示演示金额。
  final specs = [
    (
      name: '银行卡',
      subtitle: '招商储蓄卡',
      icon: Icons.account_balance_rounded,
      color: AppColors.primary,
      openingBalance: 0.0,
    ),
    (
      name: '微信',
      subtitle: '微信支付',
      icon: Icons.chat_bubble_rounded,
      color: AppColors.success,
      openingBalance: 0.0,
    ),
    (
      name: '支付宝',
      subtitle: '日常消费',
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF4B8BFF),
      openingBalance: 0.0,
    ),
    (
      name: '现金',
      subtitle: '零钱与备用金',
      icon: Icons.payments_rounded,
      color: const Color(0xFFB88955),
      openingBalance: 0.0,
    ),
    (
      name: '信用卡',
      subtitle: '本月待还',
      icon: Icons.credit_card_rounded,
      color: AppColors.financeRed,
      openingBalance: 0.0,
    ),
  ];

  return specs.map((spec) {
    final delta = records
        .where((record) => record.account == spec.name)
        .fold<double>(0, (total, record) {
      if (record.type == '收入') {
        return total + record.amount;
      }
      return total - record.amount;
    });
    return _FinanceAccountSnapshot(
      name: spec.name,
      subtitle: spec.subtitle,
      icon: spec.icon,
      color: spec.color,
      openingBalance: spec.openingBalance,
      balance: spec.openingBalance + delta,
    );
  }).toList();
}

String _signedMoney(double value) {
  return formatMoney(value);
}

class _FinanceAssetsView extends StatelessWidget {
  const _FinanceAssetsView({required this.records});

  final List<FinanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final accounts = _financeAccounts(records);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        _AssetTotalCard(accounts: accounts),
        const SizedBox(height: 14),
        _AssetRatioCard(accounts: accounts),
        const SizedBox(height: 14),
        const Text(
          '账户余额',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...accounts.map(
          (account) => _AssetAccountTile(
            icon: account.icon,
            title: account.name,
            subtitle: account.subtitle,
            amount: _signedMoney(account.balance),
            color: account.color,
          ),
        ),
      ],
    );
  }
}

class _AssetTotalCard extends StatelessWidget {
  const _AssetTotalCard({required this.accounts});

  final List<_FinanceAccountSnapshot> accounts;

  @override
  Widget build(BuildContext context) {
    final netAsset = accounts.fold<double>(
      0,
      (total, account) => total + account.balance,
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const AppIconMark(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '净资产',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _signedMoney(netAsset),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
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

class _AssetRatioCard extends StatelessWidget {
  const _AssetRatioCard({required this.accounts});

  final List<_FinanceAccountSnapshot> accounts;

  @override
  Widget build(BuildContext context) {
    final positiveAccounts =
        accounts.where((account) => account.balance > 0).toList();
    final total = positiveAccounts.fold<double>(
      0,
      (sum, account) => sum + account.balance,
    );
    final hasPositiveAssets = total > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '资产占比',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Row(
              children: [
                for (final account in positiveAccounts)
                  Expanded(
                    flex: hasPositiveAssets
                        ? math.max(1, (account.balance / total * 100).round())
                        : 1,
                    child: ColoredBox(
                      color: account.color,
                      child: const SizedBox(height: 14),
                    ),
                  ),
                if (positiveAccounts.isEmpty)
                  const Expanded(
                    child: ColoredBox(
                      color: AppColors.line,
                      child: SizedBox(height: 14),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final account in positiveAccounts.take(3))
                _LegendDot(
                  color: account.color,
                  label: '${account.name}账户',
                  detail: _signedMoney(account.balance),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.detail,
  });

  final Color color;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          detail,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AssetAccountTile extends StatelessWidget {
  const _AssetAccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('finance_asset_account_$title'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
