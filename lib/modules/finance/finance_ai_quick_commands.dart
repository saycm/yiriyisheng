// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

class _AiFinanceQuickCommand {
  const _AiFinanceQuickCommand({
    required this.key,
    required this.icon,
    required this.label,
    required this.prompt,
  });

  final String key;
  final IconData icon;
  final String label;
  final String prompt;
}

const _aiFinanceQuickCommands = [
  _AiFinanceQuickCommand(
    key: 'lunch',
    icon: Icons.restaurant_rounded,
    label: '午餐',
    prompt: '今天中午午餐花了 28 元，用微信支付',
  ),
  _AiFinanceQuickCommand(
    key: 'coffee',
    icon: Icons.local_cafe_rounded,
    label: '咖啡',
    prompt: '今天下午买咖啡花了 18 元，用支付宝支付',
  ),
  _AiFinanceQuickCommand(
    key: 'transport',
    icon: Icons.directions_bus_rounded,
    label: '交通',
    prompt: '今天早上地铁花了 5 元，用交通卡支付',
  ),
  _AiFinanceQuickCommand(
    key: 'income',
    icon: Icons.account_balance_wallet_rounded,
    label: '收入',
    prompt: '今天工资到账 3000 元，入银行卡',
  ),
  _AiFinanceQuickCommand(
    key: 'transfer',
    icon: Icons.swap_horiz_rounded,
    label: '转账',
    prompt: '从银行卡转 800 元到微信零钱',
  ),
  _AiFinanceQuickCommand(
    key: 'multi',
    icon: Icons.receipt_long_rounded,
    label: '多笔',
    prompt: '昨天中午吃饭 50 元，晚上奶茶 12 元，都用微信支付',
  ),
];
