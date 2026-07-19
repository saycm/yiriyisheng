// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

FinanceRecord? financeRecordFromAiBill(AiFinanceBillInfo bill) {
  final type = _financeTypeFromAiBill(bill);
  final title = _financeTitleFromAiBill(bill, type);
  final account = _financeAccountFromAiBill(bill);
  final rawToAccount = bill.toAccount?.trim() ?? '';
  final toAccount = bill.type == AiFinanceBillType.transfer
      ? _normalizeFinanceAccount(rawToAccount)
      : null;
  if (bill.type == AiFinanceBillType.transfer &&
      ((bill.fromAccount ?? bill.account ?? '').trim().isEmpty ||
          rawToAccount.isEmpty ||
          account == toAccount)) {
    return null;
  }
  final noteParts = [
    if ((bill.note ?? '').trim().isNotEmpty) bill.note!.trim(),
    if ((bill.account ?? '').trim().isNotEmpty) bill.account!.trim(),
    if (bill.type == AiFinanceBillType.transfer)
      '${bill.fromAccount ?? '转出'} → ${bill.toAccount ?? '转入'}',
    if ((bill.tags ?? const []).isNotEmpty) bill.tags!.join('、'),
  ];
  return FinanceRecord(
    icon: financeIconForTitle(title),
    title: title,
    subtitle: noteParts.isEmpty ? 'AI 记账' : 'AI · ${noteParts.join(' · ')}',
    amount: bill.amount?.abs() ?? 0,
    type: type,
    date: bill.time == null
        ? null
        : DateTime(bill.time!.year, bill.time!.month, bill.time!.day),
    account: account,
    toAccount: toAccount,
    tags: bill.tags ?? const [],
  );
}

String _financeTypeFromAiBill(AiFinanceBillInfo bill) {
  if (bill.type == AiFinanceBillType.transfer) {
    return '转账';
  }
  if (bill.type == AiFinanceBillType.income || (bill.amount ?? 0) > 0) {
    return '收入';
  }
  return '支出';
}

String _financeTitleFromAiBill(AiFinanceBillInfo bill, String type) {
  final raw = '${bill.category ?? ''} ${bill.note ?? ''}'.toLowerCase();
  if (type == '收入') {
    if (raw.contains('理财') || raw.contains('收益')) return '理财收益';
    if (raw.contains('奖金')) return '奖金';
    if (raw.contains('报销')) return '报销';
    if (raw.contains('红包')) return '红包';
    return '工资';
  }
  if (bill.type == AiFinanceBillType.transfer || raw.contains('转账')) {
    return '转账';
  }
  if (raw.contains('咖啡') || raw.contains('奶茶')) return '咖啡';
  if (raw.contains('交通') ||
      raw.contains('地铁') ||
      raw.contains('公交') ||
      raw.contains('打车')) {
    return '交通';
  }
  if (raw.contains('数码') || raw.contains('手机') || raw.contains('分期')) {
    return '数码分期';
  }
  if (raw.contains('购物') ||
      raw.contains('水果') ||
      raw.contains('衣') ||
      raw.contains('超市')) {
    return '购物';
  }
  if ((bill.category ?? '').trim().isNotEmpty) {
    return bill.category!.trim();
  }
  return '三餐';
}

String _financeAccountFromAiBill(AiFinanceBillInfo bill) {
  final raw = (bill.type == AiFinanceBillType.transfer
          ? bill.fromAccount ?? bill.account ?? bill.toAccount ?? ''
          : bill.account ?? bill.toAccount ?? bill.fromAccount ?? '')
      .trim();
  return _normalizeFinanceAccount(raw);
}

String _normalizeFinanceAccount(String? value) {
  final raw = value?.trim() ?? '';
  const accounts = ['银行卡', '微信', '支付宝', '现金', '信用卡'];
  if (accounts.contains(raw)) {
    return raw;
  }
  if (raw.contains('微信')) return '微信';
  if (raw.contains('支付宝')) return '支付宝';
  if (raw.contains('现金')) return '现金';
  if (raw.contains('信用')) return '信用卡';
  return '银行卡';
}
