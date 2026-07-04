// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

class FinanceHealthScore {
  const FinanceHealthScore({
    required this.total,
    required this.level,
    required this.primaryReason,
    required this.metrics,
  });

  final int total;
  final String level;
  final String primaryReason;
  final List<FinanceHealthMetric> metrics;

  FinanceHealthMetric metric(String title) {
    return metrics.firstWhere((metric) => metric.title == title);
  }
}

class FinanceHealthMetric {
  const FinanceHealthMetric({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.detail,
    required this.advice,
  });

  final String title;
  final int score;
  final int maxScore;
  final String detail;
  final String advice;

  double get progress => maxScore == 0 ? 0 : score / maxScore;
  bool get isWarning => score / maxScore < 0.6;
}

class FinanceHealthCalculator {
  const FinanceHealthCalculator();

  FinanceHealthScore calculate(
    List<FinanceRecord> records, {
    DateTime? asOf,
  }) {
    final anchor = asOf ?? _latestRecordDate(records) ?? DateTime.now();
    final monthlyRecords = records
        .where((record) => _isRecordInMonth(record, anchor))
        .toList(growable: false);
    final income = _financeTotal(monthlyRecords, '收入');
    final expense = _financeTotal(monthlyRecords, '支出');
    final metrics = [
      _cashflowMetric(income: income, expense: expense),
      _emergencyMetric(records: records, anchor: anchor),
      _budgetMetric(records: monthlyRecords),
      _fixedCostMetric(records: monthlyRecords, income: income),
      _spendingStructureMetric(records: monthlyRecords),
    ];
    final total = metrics.fold<int>(0, (sum, metric) => sum + metric.score);
    return FinanceHealthScore(
      total: total.clamp(0, 100),
      level: _healthLevel(total),
      primaryReason: _primaryReason(
        cashflow: metrics[0],
        income: income,
        expense: expense,
      ),
      metrics: metrics,
    );
  }

  DateTime? _latestRecordDate(List<FinanceRecord> records) {
    DateTime? latest;
    for (final record in records) {
      final date = record.date;
      if (date == null) {
        continue;
      }
      if (latest == null || date.isAfter(latest)) {
        latest = date;
      }
    }
    return latest;
  }

  bool _isRecordInMonth(FinanceRecord record, DateTime anchor) {
    final date = record.date;
    return date == null ||
        (date.year == anchor.year && date.month == anchor.month);
  }

  FinanceHealthMetric _cashflowMetric({
    required double income,
    required double expense,
  }) {
    if (income <= 0) {
      final score = expense <= 0 ? 12 : 0;
      return FinanceHealthMetric(
        title: '现金流能力',
        score: score,
        maxScore: 25,
        detail:
            expense <= 0 ? '暂无本月收支记录' : '本月暂无收入，支出为 ${formatMoney(expense)}',
        advice: expense <= 0 ? '先用 AI 记账补齐本月收入和支出。' : '先补录收入来源，再压缩非必要支出。',
      );
    }

    final ratio = (income - expense) / income;
    final score = switch (ratio) {
      >= 0.2 => 25,
      >= 0 => (15 + ratio / 0.2 * 10).round(),
      >= -0.2 => ((ratio + 0.2) / 0.2 * 15).round(),
      _ => 0,
    };
    final percent = (ratio * 100).round();
    return FinanceHealthMetric(
      title: '现金流能力',
      score: score,
      maxScore: 25,
      detail: '本月结余率 $percent%',
      advice: ratio >= 0.2 ? '继续保持收入大于支出的节奏。' : '优先让本月结余率回到 20% 以上。',
    );
  }

  FinanceHealthMetric _emergencyMetric({
    required List<FinanceRecord> records,
    required DateTime anchor,
  }) {
    final liquidAssets = _financeAccounts(records)
        .where((account) => account.name != '信用卡' && account.balance > 0)
        .fold<double>(0, (sum, account) => sum + account.balance);
    final recentExpense = records
        .where((record) => record.type == '支出')
        .where((record) => _isRecentRecord(record, anchor))
        .fold<double>(0, (sum, record) => sum + record.amount);
    final monthlyExpense = recentExpense / 3;
    final months = monthlyExpense <= 0 ? 0.0 : liquidAssets / monthlyExpense;
    final score = switch (months) {
      >= 6 => 25,
      >= 3 => (18 + (months - 3) / 3 * 7).round(),
      >= 1 => (8 + (months - 1) / 2 * 10).round(),
      _ => (months * 8).round(),
    };
    return FinanceHealthMetric(
      title: '应急能力',
      score: score.clamp(0, 25),
      maxScore: 25,
      detail: monthlyExpense <= 0
          ? '暂无可估算的月均支出'
          : '应急金约可覆盖 ${months.toStringAsFixed(1)} 个月支出',
      advice: months >= 3 ? '应急金已经进入安全区间。' : '先把可支配资产攒到 3 个月支出。',
    );
  }

  bool _isRecentRecord(FinanceRecord record, DateTime anchor) {
    final date = record.date;
    if (date == null) {
      return true;
    }
    final start = DateTime(anchor.year, anchor.month, anchor.day)
        .subtract(const Duration(days: 90));
    return !date.isBefore(start) && !date.isAfter(anchor);
  }

  FinanceHealthMetric _budgetMetric({required List<FinanceRecord> records}) {
    final usedByTitle = <String, double>{};
    for (final record in records.where((record) => record.type == '支出')) {
      usedByTitle.update(
        record.title,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }
    var penalty = 0.0;
    var worstTitle = '';
    var worstRatio = 0.0;
    for (final entry in usedByTitle.entries) {
      final ratio = entry.value / _budgetLimitForTitle(entry.key);
      if (ratio > worstRatio) {
        worstRatio = ratio;
        worstTitle = entry.key;
      }
      if (ratio <= 0.8) {
        continue;
      }
      penalty += ratio <= 1 ? (ratio - 0.8) / 0.2 * 2 : 2 + (ratio - 1) * 4;
    }
    final score = math.max(0, 20 - penalty.round());
    return FinanceHealthMetric(
      title: '预算纪律',
      score: score,
      maxScore: 20,
      detail: worstTitle.isEmpty
          ? '暂无分类预算压力'
          : '$worstTitle 使用率 ${(worstRatio * 100).round()}%',
      advice: worstRatio <= 0.8 ? '分类支出保持在预算线内。' : '优先处理使用率最高的分类。',
    );
  }

  double _budgetLimitForTitle(String title) {
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
    return limits[title] ?? 500.0;
  }

  FinanceHealthMetric _fixedCostMetric({
    required List<FinanceRecord> records,
    required double income,
  }) {
    final fixedCost = _fixedCostRecords(records)
        .fold<double>(0, (sum, record) => sum + record.amount);
    if (income <= 0) {
      return FinanceHealthMetric(
        title: '固定支出压力',
        score: fixedCost <= 0 ? 15 : 0,
        maxScore: 15,
        detail: fixedCost <= 0 ? '暂未识别固定支出' : '固定支出 ${formatMoney(fixedCost)}',
        advice: '补齐收入后再判断固定支出压力。',
      );
    }
    final ratio = fixedCost / income;
    final score = switch (ratio) {
      <= 0.2 => 15,
      <= 0.4 => (6 + (0.4 - ratio) / 0.2 * 9).round(),
      <= 0.5 => ((0.5 - ratio) / 0.1 * 6).round(),
      _ => 0,
    };
    return FinanceHealthMetric(
      title: '固定支出压力',
      score: score.clamp(0, 15),
      maxScore: 15,
      detail: '固定支出占收入 ${(ratio * 100).round()}%',
      advice: ratio <= 0.2 ? '固定支出占比健康。' : '先检查分期、订阅、房租等固定项目。',
    );
  }

  FinanceHealthMetric _spendingStructureMetric({
    required List<FinanceRecord> records,
  }) {
    const optionalTitles = {'咖啡', '娱乐', '购物', '数码分期', '外卖快餐'};
    final expense = _financeTotal(records, '支出');
    final optionalExpense = records
        .where((record) =>
            record.type == '支出' && optionalTitles.contains(record.title))
        .fold<double>(0, (sum, record) => sum + record.amount);
    final ratio = expense <= 0 ? 0.0 : optionalExpense / expense;
    final score = switch (ratio) {
      <= 0.3 => 15,
      <= 0.6 => (5 + (0.6 - ratio) / 0.3 * 10).round(),
      _ => 0,
    };
    return FinanceHealthMetric(
      title: '消费结构',
      score: score.clamp(0, 15),
      maxScore: 15,
      detail: '可选消费占支出 ${(ratio * 100).round()}%',
      advice: ratio <= 0.3 ? '必要支出和可选消费比例稳定。' : '先压低购物、咖啡、娱乐等可选消费。',
    );
  }

  String _healthLevel(int total) {
    if (total >= 90) {
      return '优秀';
    }
    if (total >= 75) {
      return '稳定';
    }
    if (total >= 60) {
      return '注意';
    }
    if (total >= 40) {
      return '偏紧';
    }
    return '高风险';
  }

  String _primaryReason({
    required FinanceHealthMetric cashflow,
    required double income,
    required double expense,
  }) {
    if (income > 0 && expense > income) {
      return '本月支出高于收入，现金流需要先止血';
    }
    if (income > 0 && cashflow.score >= 20) {
      final ratio = ((income - expense) / income * 100).round();
      return '现金流健康，本月结余率 $ratio%';
    }
    return cashflow.detail;
  }
}

class _FinanceHealthCard extends StatelessWidget {
  const _FinanceHealthCard({required this.records});

  final List<FinanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final score = const FinanceHealthCalculator().calculate(records);
    final color = _healthColor(score.total);
    final visibleMetrics = score.metrics.take(3).toList();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('finance_health_card'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openHealthDetail(context, score),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '财产健康值',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted.withValues(alpha: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${score.total}',
                    style: TextStyle(
                      color: color,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '分 · ${score.level}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                score.primaryReason,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              ...visibleMetrics.map(
                (metric) => _FinanceHealthMiniMetric(
                  metric: metric,
                  color: _healthColor(metric.score / metric.maxScore * 100),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHealthDetail(BuildContext context, FinanceHealthScore score) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return InfoSheetFrame(
          title: '健康值拆解',
          child: _FinanceHealthDetail(score: score),
        );
      },
    );
  }
}

class _FinanceHealthMiniMetric extends StatelessWidget {
  const _FinanceHealthMiniMetric({
    required this.metric,
    required this.color,
  });

  final FinanceHealthMetric metric;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              metric.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: metric.progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.background,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${metric.score}/${metric.maxScore}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceHealthDetail extends StatelessWidget {
  const _FinanceHealthDetail({required this.score});

  final FinanceHealthScore score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _healthColor(score.total).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: _healthColor(score.total),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${score.total} 分 · ${score.level}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      score.primaryReason,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...score.metrics.map((metric) => _FinanceHealthDetailMetric(
              metric: metric,
            )),
      ],
    );
  }
}

class _FinanceHealthDetailMetric extends StatelessWidget {
  const _FinanceHealthDetailMetric({required this.metric});

  final FinanceHealthMetric metric;

  @override
  Widget build(BuildContext context) {
    final color = _healthColor(metric.score / metric.maxScore * 100);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${metric.score}/${metric.maxScore}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: metric.progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.background,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            metric.detail,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.advice,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

Color _healthColor(num score) {
  if (score >= 75) {
    return AppColors.success;
  }
  if (score >= 60) {
    return AppColors.primary;
  }
  if (score >= 40) {
    return AppColors.accent;
  }
  return AppColors.financeRed;
}
