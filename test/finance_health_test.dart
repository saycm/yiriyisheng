import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/models/models.dart';
import 'package:pingsheng_life/modules/finance/finance.dart';

void main() {
  test('finance health score rewards stable cashflow and reserves', () {
    final score = const FinanceHealthCalculator().calculate(
      [
        FinanceRecord(
          icon: Icons.account_balance_wallet_rounded,
          title: '工资',
          subtitle: '本月收入',
          amount: 10000,
          type: '收入',
          account: '银行卡',
          date: DateTime(2026, 6, 3),
        ),
        FinanceRecord(
          icon: Icons.restaurant_rounded,
          title: '三餐',
          subtitle: '日常吃饭',
          amount: 600,
          type: '支出',
          account: '微信',
          date: DateTime(2026, 6, 6),
        ),
        FinanceRecord(
          icon: Icons.directions_bus_rounded,
          title: '交通',
          subtitle: '通勤',
          amount: 200,
          type: '支出',
          account: '支付宝',
          date: DateTime(2026, 6, 8),
        ),
      ],
      asOf: DateTime(2026, 6, 30),
    );

    expect(score.total, 100);
    expect(score.level, '优秀');
    expect(score.primaryReason, '现金流健康，本月结余率 92%');
    expect(score.metric('现金流能力').score, 25);
    expect(score.metric('应急能力').score, 25);
  });

  test('finance health score flags overspending and fixed cost pressure', () {
    final score = const FinanceHealthCalculator().calculate(
      [
        FinanceRecord(
          icon: Icons.account_balance_wallet_rounded,
          title: '工资',
          subtitle: '本月收入',
          amount: 4000,
          type: '收入',
          account: '银行卡',
          date: DateTime(2026, 6, 3),
        ),
        FinanceRecord(
          icon: Icons.shopping_bag_rounded,
          title: '购物',
          subtitle: '冲动消费',
          amount: 3000,
          type: '支出',
          account: '银行卡',
          date: DateTime(2026, 6, 6),
        ),
        FinanceRecord(
          icon: Icons.phone_iphone_rounded,
          title: '数码分期',
          subtitle: '手机分期还款',
          amount: 1000,
          type: '支出',
          account: '银行卡',
          date: DateTime(2026, 6, 8),
        ),
        FinanceRecord(
          icon: Icons.home_rounded,
          title: '房租',
          subtitle: '房租',
          amount: 2000,
          type: '支出',
          account: '银行卡',
          date: DateTime(2026, 6, 10),
        ),
        FinanceRecord(
          icon: Icons.local_cafe_rounded,
          title: '咖啡',
          subtitle: '咖啡',
          amount: 500,
          type: '支出',
          account: '银行卡',
          date: DateTime(2026, 6, 12),
        ),
      ],
      asOf: DateTime(2026, 6, 30),
    );

    expect(score.total, lessThan(40));
    expect(score.level, '高风险');
    expect(score.primaryReason, '本月支出高于收入，现金流需要先止血');
    expect(score.metric('预算纪律').score, 0);
    expect(score.metric('固定支出压力').score, 0);
    expect(score.metric('消费结构').score, 0);
  });
}
