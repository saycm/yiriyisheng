part of '../../main.dart';

const String _defaultGlmChatEndpoint =
    'https://open.bigmodel.cn/api/paas/v4/chat/completions';
const String _defaultGlmTextModel = 'glm-4-flash';

class FinanceModulePage extends StatefulWidget {
  const FinanceModulePage({
    super.key,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.foodCalories,
    required this.workoutGroups,
    required this.records,
    required this.onAddRecord,
    required this.onEditRecord,
    required this.aiEndpoint,
    required this.aiModel,
    required this.aiApiKey,
    required this.onAiConfigChanged,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final int foodCalories;
  final int workoutGroups;
  final List<FinanceRecord> records;
  final ValueChanged<FinanceRecord> onAddRecord;
  final void Function(FinanceRecord oldRecord, FinanceRecord newRecord)
      onEditRecord;
  final String aiEndpoint;
  final String aiModel;
  final String aiApiKey;
  final void Function({
    required String endpoint,
    required String model,
    required String apiKey,
  }) onAiConfigChanged;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<FinanceModulePage> createState() => _FinanceModulePageState();
}

class _FinanceModulePageState extends State<FinanceModulePage> {
  int _selectedTab = 0;
  bool _showExpense = true;
  String _trendRange = '7天';
  int _handledQuickActionToken = 0;

  @override
  void initState() {
    super.initState();
    _maybeHandleQuickAction(isInitial: true);
  }

  @override
  void didUpdateWidget(covariant FinanceModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeHandleQuickAction();
  }

  void _maybeHandleQuickAction({bool isInitial = false}) {
    if (widget.quickAction != WidgetQuickAction.addFinance ||
        widget.quickActionToken == _handledQuickActionToken) {
      return;
    }
    _handledQuickActionToken = widget.quickActionToken;
    if (isInitial) {
      _selectedTab = 1;
    } else {
      setState(() => _selectedTab = 1);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // 小组件点击“记账”后，直达财务记录页并打开可编辑明细。
      _openRecordSheet();
      widget.onQuickActionHandled();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FinanceHeader(
              onOpenModules: widget.onOpenModules,
              onAddRecord: _openRecordSheet,
              onAiRecord: _openAiRecordSheet,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FinanceBottomNav(
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedTab == 1) {
      return _FinanceRecordsView(
        records: widget.records,
        onAddRecord: widget.onAddRecord,
        onEditRecord: widget.onEditRecord,
        onAiRecord: _openAiRecordSheet,
      );
    }
    if (_selectedTab == 2) {
      return const _FinanceAssetsView();
    }
    return _FinanceOverviewView(
      showExpense: _showExpense,
      trendRange: _trendRange,
      records: widget.records,
      foodCalories: widget.foodCalories,
      workoutGroups: widget.workoutGroups,
      onOpenAssets: () => setState(() => _selectedTab = 2),
      onOpenRecords: () => setState(() => _selectedTab = 1),
      onAddRecord: _openRecordSheet,
      onAiRecord: _openAiRecordSheet,
      onToggleTrend: (showExpense) =>
          setState(() => _showExpense = showExpense),
      onChangeTrendRange: (range) => setState(() => _trendRange = range),
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

  void _openAiRecordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AiFinanceRecordSheet(
          endpoint: widget.aiEndpoint,
          model: widget.aiModel,
          apiKey: widget.aiApiKey,
          onConfigChanged: widget.onAiConfigChanged,
          onSaveAll: (records) {
            Navigator.of(context).pop();
            setState(() => _selectedTab = 1);
            // 父级插入逻辑是 insert(0)，这里反向写入能保持 AI 返回顺序。
            for (final record in records.reversed) {
              widget.onAddRecord(record);
            }
          },
        );
      },
    );
  }
}

class _FinanceHeader extends StatelessWidget {
  const _FinanceHeader({
    required this.onOpenModules,
    required this.onAddRecord,
    required this.onAiRecord,
  });

  final VoidCallback onOpenModules;
  final VoidCallback onAddRecord;
  final VoidCallback onAiRecord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Row(
        children: [
          _IconBubble(
            icon: Icons.view_sidebar_rounded,
            color: const Color(0xFF91A3FF),
            onTap: onOpenModules,
          ),
          const Expanded(
            child: Center(
              child: Text(
                '财务',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _IconBubble(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.primary,
            onTap: onAiRecord,
          ),
          const SizedBox(width: 8),
          _IconBubble(
            icon: Icons.add_card_rounded,
            color: AppColors.success,
            onTap: onAddRecord,
          ),
        ],
      ),
    );
  }
}

class _FinanceOverviewView extends StatelessWidget {
  const _FinanceOverviewView({
    required this.showExpense,
    required this.trendRange,
    required this.records,
    required this.foodCalories,
    required this.workoutGroups,
    required this.onOpenAssets,
    required this.onOpenRecords,
    required this.onAddRecord,
    required this.onAiRecord,
    required this.onToggleTrend,
    required this.onChangeTrendRange,
  });

  final bool showExpense;
  final String trendRange;
  final List<FinanceRecord> records;
  final int foodCalories;
  final int workoutGroups;
  final VoidCallback onOpenAssets;
  final VoidCallback onOpenRecords;
  final VoidCallback onAddRecord;
  final VoidCallback onAiRecord;
  final ValueChanged<bool> onToggleTrend;
  final ValueChanged<String> onChangeTrendRange;

  @override
  Widget build(BuildContext context) {
    final income = _financeTotal(records, '收入');
    final expense = _financeTotal(records, '支出');
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          18, 0, 18, _moduleSwitchBarReservedHeight + 24),
      children: [
        _NetAssetCard(
          income: income,
          expense: expense,
          onOpenAssets: onOpenAssets,
          onAddRecord: onAddRecord,
        ),
        const SizedBox(height: 14),
        _FinanceAiRecordCard(onTap: onAiRecord),
        const SizedBox(height: 14),
        _FinanceBudgetCard(
          expense: expense,
          recordCount: records.length,
        ),
        const SizedBox(height: 14),
        _ModuleLinkedSummaryCard(
          title: '财务联动',
          subtitle: '把饮食和锻炼同步到消费复盘，避免只看金额。',
          icon: Icons.account_balance_wallet_rounded,
          values: [
            ('饮食', '$foodCalories kcal'),
            ('锻炼', '$workoutGroups 组'),
          ],
        ),
        const SizedBox(height: 14),
        _FinanceBudgetInsightCard(records: records),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _FinanceMetricCard(
                icon: Icons.savings_rounded,
                iconColor: const Color(0xFF58CE82),
                label: '本月收入',
                value: _formatMoney(income),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _FinanceMetricCard(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFFFF766D),
                label: '本月支出',
                value: _formatMoney(expense),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _FinanceMetricCard(
                icon: Icons.sync_alt_rounded,
                iconColor: const Color(0xFF72C55D),
                label: '净现金流',
                value: _formatMoney(income - expense),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _FinanceMetricCard(
                icon: Icons.inventory_2_rounded,
                iconColor: const Color(0xFFF7BB4B),
                label: '本月待复核/总数',
                value: '0/${records.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _FinanceCategoryCard(records: records),
        const SizedBox(height: 14),
        _RecentFinanceRecordsCard(
          records: records,
          onOpenRecords: onOpenRecords,
        ),
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

class _NetAssetCard extends StatelessWidget {
  const _NetAssetCard({
    required this.income,
    required this.expense,
    required this.onOpenAssets,
    required this.onAddRecord,
  });

  final double income;
  final double expense;
  final VoidCallback onOpenAssets;
  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    final cashflow = income - expense;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFE9EDFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            top: 0,
            child: _FinanceIllustration(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '净资产',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¥1,555.00',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _FinanceHeroPill(
                    label: '收入',
                    value: _formatMoney(income),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _FinanceHeroPill(
                    label: '支出',
                    value: _formatMoney(expense),
                    color: AppColors.financeRed,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _FinanceHeroPill(
                label: '现金流',
                value: _formatMoney(cashflow),
                color: cashflow >= 0 ? AppColors.primary : AppColors.financeRed,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenAssets,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.account_balance_rounded, size: 17),
                      label: const Text(
                        '查看资产详情',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAddRecord,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        '记一笔',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceHeroPill extends StatelessWidget {
  const _FinanceHeroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceBudgetCard extends StatelessWidget {
  const _FinanceBudgetCard({
    required this.expense,
    required this.recordCount,
  });

  final double expense;
  final int recordCount;

  @override
  Widget build(BuildContext context) {
    const budget = 2500.0;
    final progress = (expense / budget).clamp(0.0, 1.0);
    final remaining = math.max(0.0, budget - expense);
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  '本月预算',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '剩余 ${_formatMoney(remaining)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: AppColors.primarySoft,
              color: progress > 0.82 ? AppColors.financeRed : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _BudgetMiniStat(label: '预算', value: _formatMoney(budget)),
              _BudgetMiniStat(label: '已用', value: _formatMoney(expense)),
              _BudgetMiniStat(label: '记录', value: '$recordCount 笔'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetMiniStat extends StatelessWidget {
  const _BudgetMiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

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
              _financeIconForTitle(budget.title),
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
                  '已用 ${_formatMoney(budget.used)} / ${_formatMoney(budget.limit)}',
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
                  '每月预计 ${_formatMoney(record.amount)}',
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

class _FinanceCategoryCard extends StatelessWidget {
  const _FinanceCategoryCard({required this.records});

  final List<FinanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final expenses = records.where((record) => record.type == '支出').toList();
    final total =
        expenses.fold<double>(0, (sum, record) => sum + record.amount);
    final byTitle = <String, double>{};
    for (final record in expenses) {
      byTitle.update(record.title, (value) => value + record.amount,
          ifAbsent: () => record.amount);
    }
    final entries = byTitle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(4).toList();

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
            '支出分类',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (topEntries.isEmpty)
            const Text(
              '还没有支出记录',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...topEntries.map((entry) {
              final ratio = total == 0 ? 0.0 : entry.value / total;
              return _FinanceCategoryRow(
                title: entry.key,
                amount: entry.value,
                ratio: ratio,
              );
            }),
        ],
      ),
    );
  }
}

class _FinanceCategoryRow extends StatelessWidget {
  const _FinanceCategoryRow({
    required this.title,
    required this.amount,
    required this.ratio,
  });

  final String title;
  final double amount;
  final double ratio;

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
            child: Icon(
              _financeIconForTitle(title),
              color: AppColors.primary,
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
                        title,
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
                      _formatMoney(amount),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: ratio.clamp(0.0, 1.0),
                    backgroundColor: AppColors.background,
                    color: AppColors.primary,
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

class _RecentFinanceRecordsCard extends StatelessWidget {
  const _RecentFinanceRecordsCard({
    required this.records,
    required this.onOpenRecords,
  });

  final List<FinanceRecord> records;
  final VoidCallback onOpenRecords;

  @override
  Widget build(BuildContext context) {
    final recent = records.take(3).toList();
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  '最近记录',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpenRecords,
                child: const Text(
                  '查看全部',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...recent.map(
            (record) => _CompactFinanceRecordTile(record: record),
          ),
        ],
      ),
    );
  }
}

class _CompactFinanceRecordTile extends StatelessWidget {
  const _CompactFinanceRecordTile({required this.record});

  final FinanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: record.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(record.icon, color: record.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
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
                  record.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            record.displayAmount,
            style: TextStyle(
              color: record.color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceIllustration extends StatelessWidget {
  const _FinanceIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 106,
      child: Stack(
        children: [
          Positioned(
            right: 12,
            top: 0,
            child: Container(
              width: 74,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.query_stats_rounded,
                color: AppColors.primary,
                size: 35,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 6,
            child: Container(
              width: 44,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8B8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFFF6B63E),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceMetricCard extends StatelessWidget {
  const _FinanceMetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.showExpense,
    required this.trendRange,
    required this.onToggleTrend,
    required this.onChangeRange,
  });

  final bool showExpense;
  final String trendRange;
  final ValueChanged<bool> onToggleTrend;
  final ValueChanged<String> onChangeRange;

  @override
  Widget build(BuildContext context) {
    final values = _trendValues(showExpense, trendRange);
    final total = values.fold<double>(0, (sum, value) => sum + value).round();
    final unit = showExpense ? '支出' : '收入';

    return Container(
      height: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '收支趋势',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SegmentButton(
                label: '支出',
                selected: showExpense,
                onTap: () => onToggleTrend(true),
              ),
              const SizedBox(width: 8),
              _SegmentButton(
                label: '收入',
                selected: !showExpense,
                onTap: () => onToggleTrend(false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RangeChip(
                label: '7天',
                selected: trendRange == '7天',
                onTap: () => onChangeRange('7天'),
              ),
              const SizedBox(width: 8),
              _RangeChip(
                label: '6个月',
                selected: trendRange == '6个月',
                onTap: () => onChangeRange('6个月'),
              ),
              const Spacer(),
              Text(
                '$trendRange$unit ¥$total',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _TrendPainter(
                values: values,
                range: trendRange,
                color: showExpense
                    ? AppColors.financeRed
                    : const Color(0xFF58CE82),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  List<double> _trendValues(bool showExpense, String range) {
    if (range == '6个月') {
      return showExpense
          ? const [410, 358, 492, 283, 591, 518]
          : const [2800, 3000, 3000, 3200, 3000, 3000];
    }
    return showExpense
        ? const [0, 0, 0, 2, 12, 15, 1, 14]
        : const [4, 6, 5, 7, 8, 9, 8, 10];
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.range,
    required this.color,
  });

  final List<double> values;
  final String range;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE9ECF4)
      ..strokeWidth = 1;
    final textStyle = TextStyle(
      color: AppColors.muted.withValues(alpha: 0.72),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    const left = 4.0;
    const right = 26.0;
    const top = 8.0;
    const bottom = 24.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    for (var i = 0; i <= 3; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    final maxValue = math.max(1.0, values.reduce(math.max));
    final highLabel = maxValue.round().toString();
    final middleLabel = (maxValue * 2 / 3).round().toString();
    final lowLabel = (maxValue / 3).round().toString();
    final startLabel = range == '6个月' ? '1月' : '5/17';
    final endLabel = range == '6个月' ? '6月' : '5/23';

    _drawText(canvas, highLabel, Offset(size.width - 24, top - 2), textStyle);
    _drawText(canvas, middleLabel,
        Offset(size.width - 24, top + chartHeight / 3 - 5), textStyle);
    _drawText(canvas, lowLabel,
        Offset(size.width - 24, top + chartHeight * 2 / 3 - 5), textStyle);
    _drawText(
        canvas, '0', Offset(size.width - 14, top + chartHeight - 8), textStyle);
    _drawText(canvas, startLabel, Offset(left, size.height - 14), textStyle);
    _drawText(
        canvas, endLabel, Offset(size.width - 34, size.height - 14), textStyle);

    final points = List.generate(values.length, (index) {
      final x = left + chartWidth * index / (values.length - 1);
      final y = top + chartHeight * (1 - values[index] / maxValue);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final point = points[i];
      final controlX = (previous.dx + point.dx) / 2;
      path.cubicTo(
          controlX, previous.dy, controlX, point.dy, point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, top + chartHeight)
      ..lineTo(points.first.dx, top + chartHeight)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final last = points.last;
    canvas.drawCircle(last, 4, Paint()..color = Colors.white);
    canvas.drawCircle(
        last,
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return values != oldDelegate.values ||
        range != oldDelegate.range ||
        color != oldDelegate.color;
  }
}

double _financeTotal(List<FinanceRecord> records, String type) {
  return records
      .where((record) => record.type == type)
      .fold<double>(0, (total, record) => total + record.amount);
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
            '已使用 $percent%，剩余 ${_formatMoney(math.max(0, budget.limit - budget.used))}',
      );
    },
  ).toList();
}

enum AiFinanceBillType { income, expense, transfer }

class AiFinanceBillInfo {
  const AiFinanceBillInfo({
    this.amount,
    this.time,
    this.note,
    this.category,
    this.type,
    this.account,
    this.fromAccount,
    this.toAccount,
    this.tags,
    this.confidence = 0.0,
  });

  final double? amount;
  final DateTime? time;
  final String? note;
  final String? category;
  final AiFinanceBillType? type;
  final String? account;
  final String? fromAccount;
  final String? toAccount;
  final List<String>? tags;
  final double confidence;

  AiFinanceBillInfo copyWith({
    double? amount,
    DateTime? time,
    String? note,
    String? category,
    AiFinanceBillType? type,
    String? account,
    String? fromAccount,
    String? toAccount,
    List<String>? tags,
    double? confidence,
  }) {
    return AiFinanceBillInfo(
      amount: amount ?? this.amount,
      time: time ?? this.time,
      note: note ?? this.note,
      category: category ?? this.category,
      type: type ?? this.type,
      account: account ?? this.account,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
      tags: tags ?? this.tags,
      confidence: confidence ?? this.confidence,
    );
  }

  factory AiFinanceBillInfo.fromJson(Map<String, dynamic> json) {
    return AiFinanceBillInfo(
      amount: (json['amount'] as num?)?.toDouble(),
      time: _parseAiFinanceTime(json['time']),
      note: json['note'] as String? ?? json['merchant'] as String?,
      category: json['category'] as String?,
      type: _parseAiFinanceBillType(json['type']),
      account: json['account'] as String?,
      fromAccount:
          json['from_account'] as String? ?? json['fromAccount'] as String?,
      toAccount: json['to_account'] as String? ?? json['toAccount'] as String?,
      tags: _parseAiFinanceTags(json['tags'] ?? json['tag']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'amount': amount,
      'time': time?.toIso8601String(),
      'note': note,
      'category': category,
      'type': type?.name,
      'account': account,
      'from_account': fromAccount,
      'to_account': toAccount,
      'tags': tags,
      'confidence': confidence,
    };
  }

  static DateTime? _parseAiFinanceTime(dynamic value) {
    if (value is! String) {
      return null;
    }
    final raw = value.trim();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw) ??
        DateTime.tryParse(raw.replaceAll(RegExp(r'\s+'), ''));
  }

  static AiFinanceBillType? _parseAiFinanceBillType(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().toLowerCase();
    if (text.contains('income') || text == '收入') {
      return AiFinanceBillType.income;
    }
    if (text.contains('transfer') || text == '转账' || text == '轉帳') {
      return AiFinanceBillType.transfer;
    }
    if (text.contains('expense') || text == '支出') {
      return AiFinanceBillType.expense;
    }
    return null;
  }

  static List<String>? _parseAiFinanceTags(dynamic value) {
    if (value == null) {
      return null;
    }
    final tags = <String>[];
    if (value is String) {
      tags.addAll(
        value
            .split(RegExp(r'[,\n，、;；|]+'))
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty),
      );
    } else if (value is List) {
      tags.addAll(
        value
            .map((tag) => tag.toString().trim())
            .where((tag) => tag.isNotEmpty),
      );
    }
    return tags.isEmpty ? null : tags;
  }
}

class AiFinanceJsonParser {
  const AiFinanceJsonParser();

  List<AiFinanceBillInfo> parse(String response) {
    // 这部分沿用晚安记账的核心策略：优先找 JSON 数组，失败再找单个对象。
    final arrayBlock = _extractBalancedBlock(response, '[', ']');
    if (arrayBlock != null) {
      try {
        final decoded = jsonDecode(_cleanupJson(arrayBlock));
        if (decoded is List) {
          final bills = <AiFinanceBillInfo>[];
          for (final item in decoded) {
            final map = _asStringMap(item);
            if (map == null) {
              continue;
            }
            final bill = _sanitize(AiFinanceBillInfo.fromJson(map));
            if (bill != null) {
              bills.add(bill);
            }
          }
          if (bills.isNotEmpty) {
            return bills;
          }
        }
      } catch (_) {
        // AI 可能包 Markdown 或生成 JSON5 风格，继续走单对象兜底。
      }
    }

    final objectBlock = _extractBalancedBlock(response, '{', '}');
    if (objectBlock == null) {
      return const [];
    }
    try {
      final map = _asStringMap(jsonDecode(_cleanupJson(objectBlock)));
      if (map == null) {
        return const [];
      }
      final bill = _sanitize(AiFinanceBillInfo.fromJson(map));
      return bill == null ? const [] : [bill];
    } catch (_) {
      return const [];
    }
  }

  AiFinanceBillInfo? _sanitize(AiFinanceBillInfo bill) {
    final amount = bill.amount;
    if (amount == null || amount.abs() <= 0) {
      return null;
    }
    return bill.time == null ? bill.copyWith(time: DateTime.now()) : bill;
  }

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  String _cleanupJson(String input) {
    final out = StringBuffer();
    var inString = false;
    var escaped = false;
    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (inString) {
        out.write(char);
        if (escaped) {
          escaped = false;
        } else if (char == '\\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }
      if (char == '"') {
        inString = true;
        out.write(char);
        continue;
      }
      if (char == ',') {
        var next = index + 1;
        while (next < input.length && input[next].trim().isEmpty) {
          next++;
        }
        if (next < input.length && (input[next] == '}' || input[next] == ']')) {
          continue;
        }
      }
      out.write(char);
    }
    return out.toString();
  }

  String? _extractBalancedBlock(String text, String open, String close) {
    final start = text.indexOf(open);
    if (start < 0) {
      return null;
    }
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var index = start; index < text.length; index++) {
      final char = text[index];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == '\\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (inString) {
        continue;
      }
      if (char == open) {
        depth++;
      } else if (char == close) {
        depth--;
        if (depth == 0) {
          return text.substring(start, index + 1);
        }
      }
    }
    return null;
  }
}

class AiFinancePromptBuilder {
  const AiFinancePromptBuilder();

  static const _expenseCategories = [
    '三餐',
    '餐饮',
    '咖啡',
    '奶茶',
    '交通',
    '购物',
    '数码分期',
    '娱乐',
    '居家',
    '通讯',
    '水电',
    '医疗',
    '教育',
  ];

  static const _incomeCategories = [
    '工资',
    '理财收益',
    '奖金',
    '报销',
    '红包',
    '兼职',
  ];

  String build({
    required String text,
    DateTime? now,
  }) {
    final ts = now ?? DateTime.now();
    final currentDate = '${ts.year}-${_pad(ts.month)}-${_pad(ts.day)}';
    final currentTime = '$currentDate ${_pad(ts.hour)}:${_pad(ts.minute)}';
    return '''从以下自然语言中提取记账信息，返回 JSON 数组。

当前时间：$currentTime

用户输入：
$text

分类列表：
支出：${_expenseCategories.join('、')}
收入：${_incomeCategories.join('、')}
账户列表：现金、支付宝、微信、银行卡、信用卡

输出要求：
- 只返回 JSON 数组，不要解释
- 即使只有一笔，也包成 [{...}]
- 多笔消费/收入拆成多条记录
- amount：支出为负数，收入为正数，转账为正数
- time：ISO8601 格式；“昨天/前天/早上/中午/晚上”等相对时间按当前时间推断
- note：15 字以内，优先商户/商品/用途
- category：从分类列表中选择最接近的一项
- type：income、expense 或 transfer
- account/from_account/to_account/tag/tags 可选

示例：
"昨天中午吃饭50，晚上奶茶12" → [{"amount":-50,"time":"${currentDate}T12:00:00","note":"吃饭","category":"三餐","type":"expense"},{"amount":-12,"time":"${currentDate}T19:00:00","note":"奶茶","category":"咖啡","type":"expense"}]
"工资到账3000" → [{"amount":3000,"time":"${currentDate}T09:00:00","note":"工资到账","category":"工资","type":"income"}]''';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}

class AiFinanceException implements Exception {
  const AiFinanceException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef AiFinanceTransport = Future<String> Function({
  required Uri uri,
  required String apiKey,
  required Map<String, Object?> payload,
});

class AiFinanceClient {
  AiFinanceClient({
    this.parser = const AiFinanceJsonParser(),
    this.promptBuilder = const AiFinancePromptBuilder(),
    AiFinanceTransport? transport,
  }) : _transport = transport ?? _defaultTransport;

  final AiFinanceJsonParser parser;
  final AiFinancePromptBuilder promptBuilder;
  final AiFinanceTransport _transport;

  Future<List<AiFinanceBillInfo>> parseText({
    required String text,
    required String apiKey,
    required String endpoint,
    required String model,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw const AiFinanceException('请先输入要记账的内容');
    }
    if (apiKey.trim().isEmpty) {
      throw const AiFinanceException('请先填写 AI 接口 Key');
    }

    final uri = _resolveEndpoint(endpoint);
    try {
      final body = await _transport(
        uri: uri,
        apiKey: apiKey,
        payload: {
          'model': model.trim().isEmpty ? _defaultGlmTextModel : model.trim(),
          'temperature': 0.1,
          'messages': [
            {
              'role': 'system',
              'content': '你是严谨的记账信息提取器，只输出 JSON 数组。',
            },
            {
              'role': 'user',
              'content': promptBuilder.build(text: trimmedText),
            },
          ],
        },
      );
      final content = _extractChatContent(body);
      final bills = parser.parse(content);
      if (bills.isEmpty) {
        throw const AiFinanceException('AI 没有返回可用账单，请换一种说法再试');
      }
      return bills;
    } on AiFinanceException {
      rethrow;
    } catch (error) {
      throw AiFinanceException('AI 记账失败：$error');
    }
  }

  static Future<String> _defaultTransport({
    required Uri uri,
    required String apiKey,
    required Map<String, Object?> payload,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiFinanceException('AI 接口请求失败：${response.statusCode} $body');
      }
      return body;
    } finally {
      client.close(force: true);
    }
  }

  Uri _resolveEndpoint(String endpoint) {
    final raw =
        endpoint.trim().isEmpty ? _defaultGlmChatEndpoint : endpoint.trim();
    final uri = Uri.parse(raw);
    if (uri.path.isEmpty || uri.path == '/') {
      return uri.replace(path: '/v1/chat/completions');
    }
    if (uri.path.endsWith('/v1')) {
      return uri.replace(path: '${uri.path}/chat/completions');
    }
    if (uri.path.endsWith('/v1/')) {
      return uri.replace(path: '${uri.path}chat/completions');
    }
    return uri;
  }

  String _extractChatContent(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AiFinanceException('AI 接口返回格式不是 JSON 对象');
    }
    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic> && message['content'] is String) {
          return message['content'] as String;
        }
        if (first['text'] is String) {
          return first['text'] as String;
        }
      }
    }
    throw const AiFinanceException('AI 接口返回中没有 message.content');
  }
}

class AiFinanceRecordDraft {
  AiFinanceRecordDraft({
    required this.bill,
    required this.record,
    this.selected = true,
  });

  final AiFinanceBillInfo bill;
  final FinanceRecord record;
  bool selected;
}

FinanceRecord _financeRecordFromAiBill(AiFinanceBillInfo bill) {
  final type = _financeTypeFromAiBill(bill);
  final title = _financeTitleFromAiBill(bill, type);
  final noteParts = [
    if ((bill.note ?? '').trim().isNotEmpty) bill.note!.trim(),
    if ((bill.account ?? '').trim().isNotEmpty) bill.account!.trim(),
    if (bill.type == AiFinanceBillType.transfer)
      '${bill.fromAccount ?? '转出'} → ${bill.toAccount ?? '转入'}',
    if ((bill.tags ?? const []).isNotEmpty) bill.tags!.join('、'),
  ];
  return FinanceRecord(
    icon: _financeIconForTitle(title),
    title: title,
    subtitle: noteParts.isEmpty ? 'AI 记账' : 'AI · ${noteParts.join(' · ')}',
    amount: bill.amount?.abs() ?? 0,
    type: type,
  );
}

String _financeTypeFromAiBill(AiFinanceBillInfo bill) {
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

class _FinanceRecordsView extends StatefulWidget {
  const _FinanceRecordsView({
    required this.records,
    required this.onAddRecord,
    required this.onEditRecord,
    required this.onAiRecord,
  });

  final List<FinanceRecord> records;
  final ValueChanged<FinanceRecord> onAddRecord;
  final void Function(FinanceRecord oldRecord, FinanceRecord newRecord)
      onEditRecord;
  final VoidCallback onAiRecord;

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
      padding: const EdgeInsets.fromLTRB(
          18, 0, 18, _moduleSwitchBarReservedHeight + 24),
      children: [
        _FinanceMonthSummary(records: widget.records),
        const SizedBox(height: 14),
        _FinanceAddRecordCard(
          onTap: () => _openRecordSheet(),
        ),
        const SizedBox(height: 14),
        _FinanceAiRecordCard(onTap: widget.onAiRecord),
        const SizedBox(height: 14),
        Row(
          children: [
            _RangeChip(
              label: '全部',
              selected: _filter == '全部',
              onTap: () => setState(() => _filter = '全部'),
            ),
            const SizedBox(width: 8),
            _RangeChip(
              label: '支出',
              selected: _filter == '支出',
              onTap: () => setState(() => _filter = '支出'),
            ),
            const SizedBox(width: 8),
            _RangeChip(
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

class _FinanceAssetsView extends StatelessWidget {
  const _FinanceAssetsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          18, 0, 18, _moduleSwitchBarReservedHeight + 24),
      children: const [
        _AssetTotalCard(),
        SizedBox(height: 14),
        _AssetRatioCard(),
        SizedBox(height: 14),
        _AssetAccountTile(
          icon: Icons.account_balance_rounded,
          title: '银行卡',
          subtitle: '招商储蓄卡',
          amount: '¥1,200.00',
          color: AppColors.primary,
        ),
        _AssetAccountTile(
          icon: Icons.payments_rounded,
          title: '现金',
          subtitle: '零钱与备用金',
          amount: '¥355.00',
          color: AppColors.success,
        ),
        _AssetAccountTile(
          icon: Icons.credit_card_rounded,
          title: '信用卡',
          subtitle: '本月待还',
          amount: '-¥48.00',
          color: AppColors.financeRed,
        ),
      ],
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
              value: _formatMoney(income),
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SmallFinanceStat(
              title: '支出',
              value: _formatMoney(expense),
              color: AppColors.financeRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SmallFinanceStat(
              title: '结余',
              value: _formatMoney(income - expense),
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

class _FinanceAddRecordCard extends StatelessWidget {
  const _FinanceAddRecordCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('finance_add_record'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_card_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '记一笔',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _FinanceAiRecordCard extends StatelessWidget {
  const _FinanceAiRecordCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('finance_ai_record'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI 记账',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _AiFinanceRecordSheet extends StatefulWidget {
  const _AiFinanceRecordSheet({
    required this.endpoint,
    required this.model,
    required this.apiKey,
    required this.onConfigChanged,
    required this.onSaveAll,
  });

  final String endpoint;
  final String model;
  final String apiKey;
  final void Function({
    required String endpoint,
    required String model,
    required String apiKey,
  }) onConfigChanged;
  final ValueChanged<List<FinanceRecord>> onSaveAll;

  @override
  State<_AiFinanceRecordSheet> createState() => _AiFinanceRecordSheetState();
}

class _AiFinanceRecordSheetState extends State<_AiFinanceRecordSheet> {
  final _client = AiFinanceClient();
  late final TextEditingController _inputController;
  late final TextEditingController _endpointController;
  late final TextEditingController _modelController;
  late final TextEditingController _apiKeyController;
  final List<AiFinanceRecordDraft> _drafts = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _endpointController = TextEditingController(text: widget.endpoint);
    _modelController = TextEditingController(text: widget.model);
    _apiKeyController = TextEditingController(text: widget.apiKey);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '智谱 GLM 记账',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _FinanceTextField(
                  keyValue: 'ai_finance_input',
                  controller: _inputController,
                  label: '自然语言记账',
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _FinanceTextField(
                  keyValue: 'ai_finance_endpoint',
                  controller: _endpointController,
                  label: '智谱 API 地址',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FinanceTextField(
                        keyValue: 'ai_finance_model',
                        controller: _modelController,
                        label: 'GLM 模型',
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('ai_finance_api_key'),
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  _AiFinanceMessageCard(
                    icon: Icons.error_outline_rounded,
                    color: AppColors.financeRed,
                    message: _error!,
                  ),
                ],
                if (_drafts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const _ModuleSectionTitle(
                    icon: Icons.receipt_long_rounded,
                    title: '解析结果',
                  ),
                  const SizedBox(height: 10),
                  ..._drafts.map(
                    (draft) => _AiFinanceDraftTile(
                      draft: draft,
                      onChanged: (selected) {
                        setState(() => draft.selected = selected);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('run_ai_finance_parse'),
                  onPressed: _loading ? null : _parse,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_loading ? '解析中' : 'AI 解析'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('save_ai_finance_records'),
                  onPressed: _drafts.any((draft) => draft.selected)
                      ? _saveSelected
                      : null,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('保存全部'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _parse() async {
    setState(() {
      _loading = true;
      _error = null;
      _drafts.clear();
    });
    widget.onConfigChanged(
      endpoint: _endpointController.text.trim(),
      model: _modelController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );
    try {
      final bills = await _client.parseText(
        text: _inputController.text,
        endpoint: _endpointController.text,
        model: _modelController.text,
        apiKey: _apiKeyController.text,
      );
      setState(() {
        _drafts
          ..clear()
          ..addAll(
            bills.map(
              (bill) => AiFinanceRecordDraft(
                bill: bill,
                record: _financeRecordFromAiBill(bill),
              ),
            ),
          );
      });
    } on AiFinanceException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = 'AI 记账失败：$error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _saveSelected() {
    final records = _drafts
        .where((draft) => draft.selected)
        .map((draft) => draft.record)
        .toList();
    if (records.isEmpty) {
      setState(() => _error = '请至少选择一笔记录');
      return;
    }
    widget.onSaveAll(records);
  }
}

class _AiFinanceMessageCard extends StatelessWidget {
  const _AiFinanceMessageCard({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFinanceDraftTile extends StatelessWidget {
  const _AiFinanceDraftTile({
    required this.draft,
    required this.onChanged,
  });

  final AiFinanceRecordDraft draft;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final record = draft.record;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: draft.selected,
            activeColor: AppColors.primary,
            onChanged: (value) => onChanged(value ?? false),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: record.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(record.icon, color: record.color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            record.displayAmount,
            style: TextStyle(
              color: record.color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceRecordSheet extends StatefulWidget {
  const _FinanceRecordSheet({
    required this.record,
    required this.onSave,
  });

  final FinanceRecord? record;
  final ValueChanged<FinanceRecord> onSave;

  @override
  State<_FinanceRecordSheet> createState() => _FinanceRecordSheetState();
}

class _FinanceCategorySpec {
  const _FinanceCategorySpec(this.icon, this.title);

  final IconData icon;
  final String title;
}

class _FinanceRecordSheetState extends State<_FinanceRecordSheet> {
  late final TextEditingController _subtitleController;
  late String _type;
  late _FinanceCategorySpec _category;
  late String _amountText;
  late DateTime _date;
  double _accumulator = 0;
  String? _operator;

  static const _expenseCategories = [
    _FinanceCategorySpec(Icons.restaurant_rounded, '三餐'),
    _FinanceCategorySpec(Icons.delivery_dining_rounded, '外卖快餐'),
    _FinanceCategorySpec(Icons.local_cafe_rounded, '咖啡'),
    _FinanceCategorySpec(Icons.directions_bus_rounded, '交通'),
    _FinanceCategorySpec(Icons.shopping_bag_rounded, '购物'),
    _FinanceCategorySpec(Icons.phone_iphone_rounded, '数码分期'),
    _FinanceCategorySpec(Icons.movie_rounded, '娱乐'),
    _FinanceCategorySpec(Icons.home_rounded, '居家'),
    _FinanceCategorySpec(Icons.medical_services_rounded, '医疗'),
    _FinanceCategorySpec(Icons.school_rounded, '教育'),
  ];

  static const _incomeCategories = [
    _FinanceCategorySpec(Icons.account_balance_wallet_rounded, '工资'),
    _FinanceCategorySpec(Icons.emoji_events_rounded, '奖金'),
    _FinanceCategorySpec(Icons.savings_rounded, '理财收益'),
    _FinanceCategorySpec(Icons.assignment_return_rounded, '报销'),
    _FinanceCategorySpec(Icons.redeem_rounded, '红包'),
    _FinanceCategorySpec(Icons.work_history_rounded, '兼职'),
  ];

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _type = record?.type ?? '支出';
    _category = _categoryForRecord(record);
    _subtitleController = TextEditingController(
        text: record?.subtitle == '手动记录' ? '' : record?.subtitle ?? '');
    _amountText = record == null ? '0' : _formatAmountInput(record.amount);
    _date = record?.date ?? DateUtils.dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.96,
      ),
      padding: EdgeInsets.fromLTRB(18, 8, 18, bottomInset + 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.record == null ? '记一笔' : '编辑记录',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeTabs(),
                    const SizedBox(height: 8),
                    _buildCategoryStrip(),
                    const SizedBox(height: 8),
                    _buildAmountDisplay(),
                    const SizedBox(height: 8),
                    _FinanceTextField(
                      keyValue: 'finance_record_subtitle',
                      controller: _subtitleController,
                      label: '备注',
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 6),
                    _buildAmountKeyboard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FinanceTypeButton(
              buttonKey: const ValueKey('finance_category_expense'),
              label: '支出',
              selected: _type == '支出',
              onTap: () => _setType('支出'),
            ),
          ),
          Expanded(
            child: _FinanceTypeButton(
              buttonKey: const ValueKey('finance_category_income'),
              label: '收入',
              selected: _type == '收入',
              onTap: () => _setType('收入'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _visibleCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _visibleCategories[index];
          final selected = category.title == _category.title;
          return _FinanceCategoryButton(
            buttonKey: ValueKey('finance_category_${category.title}'),
            category: category,
            selected: selected,
            onTap: () => setState(() => _category = category),
          );
        },
      ),
    );
  }

  Widget _buildAmountDisplay() {
    final total = _currentTotal();
    return Container(
      key: const ValueKey('finance_record_amount'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(_category.icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_category.title} · $_type',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '金额',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatMoney(total),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('finance_amount_clear'),
            tooltip: '清空金额',
            onPressed: _clearAmount,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountKeyboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyWidth = constraints.maxWidth / 4;
        Widget cell(Widget child) => SizedBox(width: keyWidth, child: child);
        return Column(
          children: [
            Row(
              children: [
                cell(_FinanceAmountKey(
                  label: '7',
                  onTap: () => _appendAmount('7'),
                )),
                cell(_FinanceAmountKey(
                  label: '8',
                  onTap: () => _appendAmount('8'),
                )),
                cell(_FinanceAmountKey(
                  label: '9',
                  onTap: () => _appendAmount('9'),
                )),
                cell(_FinanceAmountKey(
                  label: _formatDateKey(_date),
                  keyValue: 'finance_record_date',
                  dense: true,
                  onTap: _pickDate,
                )),
              ],
            ),
            Row(
              children: [
                cell(_FinanceAmountKey(
                  label: '4',
                  onTap: () => _appendAmount('4'),
                )),
                cell(_FinanceAmountKey(
                  label: '5',
                  onTap: () => _appendAmount('5'),
                )),
                cell(_FinanceAmountKey(
                  label: '6',
                  onTap: () => _appendAmount('6'),
                )),
                cell(_FinanceAmountKey(
                  label: '+',
                  keyValue: 'finance_amount_op_add',
                  secondary: true,
                  onTap: () => _applyOperator('+'),
                )),
              ],
            ),
            Row(
              children: [
                cell(_FinanceAmountKey(
                  label: '1',
                  onTap: () => _appendAmount('1'),
                )),
                cell(_FinanceAmountKey(
                  label: '2',
                  onTap: () => _appendAmount('2'),
                )),
                cell(_FinanceAmountKey(
                  label: '3',
                  onTap: () => _appendAmount('3'),
                )),
                cell(_FinanceAmountKey(
                  label: '-',
                  keyValue: 'finance_amount_op_minus',
                  secondary: true,
                  onTap: () => _applyOperator('-'),
                )),
              ],
            ),
            Row(
              children: [
                cell(_FinanceAmountKey(
                  label: '.',
                  keyValue: 'finance_amount_decimal',
                  onTap: () => _appendAmount('.'),
                )),
                cell(_FinanceAmountKey(
                  label: '0',
                  onTap: () => _appendAmount('0'),
                )),
                cell(_FinanceAmountKey(
                  icon: Icons.backspace_outlined,
                  keyValue: 'finance_amount_backspace',
                  onTap: _backspaceAmount,
                )),
                cell(_FinanceAmountKey(
                  label: _operator == null ? '完成' : '=',
                  keyValue: 'save_finance_record',
                  primary: true,
                  onTap: _operator == null ? _save : _finishCalculation,
                )),
              ],
            ),
          ],
        );
      },
    );
  }

  void _save() {
    final amount = _currentTotal().abs();
    if (amount <= 0) {
      return;
    }
    widget.onSave(
      FinanceRecord(
        icon: _category.icon,
        title: _category.title,
        subtitle: _subtitleController.text.trim().isEmpty
            ? '手动记录'
            : _subtitleController.text.trim(),
        amount: amount,
        type: _type,
        date: _date,
      ),
    );
  }

  List<_FinanceCategorySpec> get _visibleCategories =>
      _type == '收入' ? _incomeCategories : _expenseCategories;

  _FinanceCategorySpec _categoryForRecord(FinanceRecord? record) {
    final categories = (record?.type ?? _type) == '收入'
        ? _incomeCategories
        : _expenseCategories;
    if (record == null) {
      return categories.first;
    }
    for (final category in categories) {
      if (category.title == record.title) {
        return category;
      }
    }
    return _FinanceCategorySpec(
        _financeIconForTitle(record.title), record.title);
  }

  void _setType(String type) {
    if (_type == type) {
      return;
    }
    setState(() {
      _type = type;
      final currentStillVisible = _visibleCategories
          .any((category) => category.title == _category.title);
      if (!currentStillVisible) {
        _category = _visibleCategories.first;
      }
    });
  }

  void _appendAmount(String value) {
    if (value == '.' && _amountText.contains('.')) {
      return;
    }
    if (_amountText.contains('.') && value != '.') {
      final decimalCount = _amountText.length - _amountText.indexOf('.') - 1;
      if (decimalCount >= 2) {
        return;
      }
    }
    setState(() {
      if (_amountText == '0' && value != '.') {
        _amountText = value;
      } else {
        _amountText = '$_amountText$value';
      }
    });
    SystemSound.play(SystemSoundType.click);
  }

  void _clearAmount() {
    setState(() {
      _amountText = '0';
      _accumulator = 0;
      _operator = null;
    });
    HapticFeedback.selectionClick();
  }

  void _backspaceAmount() {
    setState(() {
      _amountText = _amountText.length <= 1
          ? '0'
          : _amountText.substring(0, _amountText.length - 1);
    });
    SystemSound.play(SystemSoundType.click);
  }

  void _applyOperator(String operator) {
    final current = double.tryParse(_amountText) ?? 0;
    setState(() {
      if (_operator == '+') {
        _accumulator += current;
      } else if (_operator == '-') {
        _accumulator -= current;
      } else {
        _accumulator = current;
      }
      _operator = operator;
      _amountText = '0';
    });
    HapticFeedback.selectionClick();
  }

  void _finishCalculation() {
    final current = double.tryParse(_amountText) ?? 0;
    final total = _operator == '+'
        ? _accumulator + current
        : _operator == '-'
            ? _accumulator - current
            : current;
    setState(() {
      _amountText = _formatAmountInput(total.abs());
      _accumulator = 0;
      _operator = null;
    });
    HapticFeedback.selectionClick();
  }

  double _currentTotal() {
    final current = double.tryParse(_amountText) ?? 0;
    if (_operator == '+') {
      return _accumulator + current;
    }
    if (_operator == '-') {
      return _accumulator - current;
    }
    return current;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  String _formatAmountInput(double amount) {
    final fixed = amount.toStringAsFixed(2);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatDateKey(DateTime date) => '${date.month}/${date.day}';
}

class _FinanceTypeButton extends StatelessWidget {
  const _FinanceTypeButton({
    required this.buttonKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FinanceCategoryButton extends StatelessWidget {
  const _FinanceCategoryButton({
    required this.buttonKey,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final _FinanceCategorySpec category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 68,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              color: selected ? AppColors.primary : AppColors.muted,
              size: 21,
            ),
            const SizedBox(height: 4),
            Text(
              category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceAmountKey extends StatelessWidget {
  const _FinanceAmountKey({
    this.label,
    this.icon,
    this.keyValue,
    this.primary = false,
    this.secondary = false,
    this.dense = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final String? keyValue;
  final bool primary;
  final bool secondary;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = primary
        ? AppColors.primary
        : secondary
            ? AppColors.primarySoft
            : AppColors.background;
    final foreground = primary
        ? Colors.white
        : secondary
            ? AppColors.primary
            : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: ValueKey(keyValue ?? 'finance_amount_key_$label'),
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 38,
            child: Center(
              child: icon == null
                  ? Text(
                      label!,
                      style: TextStyle(
                        color: foreground,
                        fontSize: dense ? 13 : 18,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : Icon(icon, color: foreground, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinanceTextField extends StatelessWidget {
  const _FinanceTextField({
    required this.keyValue,
    required this.controller,
    required this.label,
    required this.keyboardType,
    this.maxLines = 1,
  });

  final String keyValue;
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey(keyValue),
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
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
                  Text(
                    record.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _AssetTotalCard extends StatelessWidget {
  const _AssetTotalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          _AppIconMark(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '净资产',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '¥1,555.00',
                  style: TextStyle(
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
  const _AssetRatioCard();

  @override
  Widget build(BuildContext context) {
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
              children: const [
                Expanded(
                  flex: 77,
                  child: ColoredBox(
                    color: AppColors.primary,
                    child: SizedBox(height: 14),
                  ),
                ),
                Expanded(
                  flex: 23,
                  child: ColoredBox(
                    color: AppColors.success,
                    child: SizedBox(height: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendDot(color: AppColors.primary, label: '银行卡 77%'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.success, label: '现金 23%'),
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
  });

  final Color color;
  final String label;

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
