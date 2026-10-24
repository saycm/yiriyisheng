// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

/// 财务健康总分：总分、等级、主要原因和各项指标。
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

  /// 按标题取出单项指标，供卡片和详情页查找指定维度。
  FinanceHealthMetric metric(String title) {
    return metrics.firstWhere((metric) => metric.title == title);
  }
}

/// 单项财务健康指标：得分、满分、说明和建议。
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

  /// 当前得分占满分的比例，用于绘制进度条。
  double get progress => maxScore == 0 ? 0 : score / maxScore;

  /// 得分低于满分的 60% 时标记为需要关注。
  bool get isWarning => score / maxScore < 0.6;
}

/// 财务健康计算器：根据当月收支、应急金、预算、固定成本和消费结构打分。
class FinanceHealthCalculator {
  const FinanceHealthCalculator();

  /// 以记录所在月份为统计口径，计算现金流、应急金、预算、固定支出和消费结构五项得分。
  FinanceHealthScore calculate(
    List<FinanceRecord> records, {
    DateTime? asOf,
  }) {
    // 以最近一笔记录的日期作为“当月”锚点，没有记录时用今天。
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
      _fixedCostMetric(
        records: monthlyRecords,
        income: income,
        month: anchor,
      ),
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

  /// 扫描全部记录，找到最近一笔有效日期；日期缺失的记录会被忽略。
  DateTime? _latestRecordDate(List<FinanceRecord> records) {
    // 找出最近一笔记录日期，作为计算基准月。
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

  /// 判断记录是否属于锚点月份；没有日期的记录默认计入当前统计。
  bool _isRecordInMonth(FinanceRecord record, DateTime anchor) {
    final date = record.date;
    return date == null ||
        (date.year == anchor.year && date.month == anchor.month);
  }

  /// 现金流指标（25 分）：按月结余率评分，收入越高且支出控制越好，得分越高。
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

  /// 应急能力指标（25 分）：用非信用卡流动资产除以近三个月平均月支出，衡量可支撑月数。
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

  /// 判断记录是否位于锚点日期前 90 天内，用于估算近期月均支出。
  bool _isRecentRecord(FinanceRecord record, DateTime anchor) {
    final date = record.date;
    if (date == null) {
      return true;
    }
    final start = DateTime(anchor.year, anchor.month, anchor.day)
        .subtract(const Duration(days: 90));
    return !date.isBefore(start) && !date.isAfter(anchor);
  }

  /// 预算纪律指标（20 分）：按分类汇总支出，超过预算线越多扣分越多。
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

  /// 各消费分类的默认月度预算上限；未配置的分类按 500 元处理。
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

  /// 固定支出压力指标（15 分）：计算房租、分期等固定支出占收入的比例。
  FinanceHealthMetric _fixedCostMetric({
    required List<FinanceRecord> records,
    required double income,
    required DateTime month,
  }) {
    final fixedCost = _fixedCostRecords(records, month: month)
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

  /// 消费结构指标（15 分）：统计咖啡、娱乐、购物等可选消费占总支出的比例。
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

  /// 把财务健康总分映射成优秀、稳定、注意、偏紧或高风险等级。
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

  /// 选择最能解释当前财务状态的一句话，优先提示支出超过收入的情况。
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

/// 财务健康摘要卡片：总分和主要指标。
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
      child: GlassSurface(
        borderRadius: 16,
        color: AppColors.surface.withValues(alpha: 0.80),
        child: InkWell(
          key: const ValueKey('finance_health_card'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openHealthDetail(context, score),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
      ),
    );
  }

  /// 打开健康值详情底部弹窗，展示五项指标的拆解说明。
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

/// 健康卡里的小指标（图标 + 分数）。
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

/// 财务健康详情页：展示每项指标的得分和建议。
class _FinanceHealthDetail extends StatelessWidget {
  const _FinanceHealthDetail({required this.score});

  final FinanceHealthScore score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassSurface(
          borderRadius: 16,
          color: AppColors.surface.withValues(alpha: 0.80),
          padding: const EdgeInsets.all(16),
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

/// 详情页中的单项指标行。
class _FinanceHealthDetailMetric extends StatelessWidget {
  const _FinanceHealthDetailMetric({required this.metric});

  final FinanceHealthMetric metric;

  @override
  Widget build(BuildContext context) {
    final color = _healthColor(metric.score / metric.maxScore * 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.78),
        padding: const EdgeInsets.all(14),
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
      ),
    );
  }
}

// 根据健康分数选择绿色、黄色或红色提示。
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
