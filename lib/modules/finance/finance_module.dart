// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

class FinanceModulePage extends StatefulWidget {
  const FinanceModulePage({
    super.key,
    required this.moduleNav,
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
    required this.aiParseStrategy,
    required this.aiCustomPrompt,
    required this.onAiConfigChanged,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final Widget moduleNav;
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
  final AiFinanceParseStrategy aiParseStrategy;
  final String aiCustomPrompt;
  final void Function({
    required String endpoint,
    required String model,
    required String apiKey,
    AiFinanceParseStrategy? parseStrategy,
    String? customPrompt,
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
        child: Stack(
          children: [
            Column(
              children: [
                _FinanceHeader(
                  onOpenModules: widget.onOpenModules,
                  onAiRecord: _openAiRecordSheet,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: widget.moduleNav,
                ),
                _FinanceHeaderActions(
                  onAiRecord: _openAiRecordSheet,
                  onAddRecord: () => _openRecordSheet(),
                ),
                Expanded(child: _buildContent()),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: moduleSwitchBarBottomGap),
                child: FinanceBottomNav(
                  selectedIndex: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
              ),
            ),
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
      );
    }
    if (_selectedTab == 2) {
      return _FinanceAssetsView(records: widget.records);
    }
    return _FinanceOverviewView(
      showExpense: _showExpense,
      trendRange: _trendRange,
      records: widget.records,
      onOpenAssets: () => setState(() => _selectedTab = 2),
      onAddRecord: _openRecordSheet,
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _FinanceAiAssistantPage(
          endpoint: widget.aiEndpoint,
          model: widget.aiModel,
          apiKey: widget.aiApiKey,
          parseStrategy: widget.aiParseStrategy,
          customPrompt: widget.aiCustomPrompt,
          onConfigChanged: widget.onAiConfigChanged,
          onSaveAll: (records) {
            if (mounted) {
              setState(() => _selectedTab = 1);
            }
            // 父级插入逻辑是 insert(0)，这里反向写入能保持 AI 返回顺序。
            for (final record in records.reversed) {
              widget.onAddRecord(record);
            }
          },
        ),
      ),
    );
  }
}

class _FinanceHeader extends StatelessWidget {
  const _FinanceHeader({
    required this.onOpenModules,
    required this.onAiRecord,
  });

  final VoidCallback onOpenModules;
  final VoidCallback onAiRecord;

  @override
  Widget build(BuildContext context) {
    return ModuleGlassHeader(
      module: LifeModule.finance,
      title: '财务',
      onOpenModules: onOpenModules,
      onOpenMore: onAiRecord,
    );
  }
}

class _FinanceHeaderActions extends StatelessWidget {
  const _FinanceHeaderActions({
    required this.onAiRecord,
    required this.onAddRecord,
  });

  final VoidCallback onAiRecord;
  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: KeyedSubtree(
              key: const ValueKey('finance_ai_record'),
              child: HeaderActionPill(
                icon: Icons.auto_awesome_rounded,
                label: 'AI 记账',
                color: AppColors.accent,
                onTap: onAiRecord,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: HeaderActionPill(
              icon: Icons.add_card_rounded,
              label: '记一笔',
              color: AppColors.primary,
              onTap: onAddRecord,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    super.key,
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

double _financeTotal(List<FinanceRecord> records, String type) {
  return records
      .where((record) => record.type == type)
      .fold<double>(0, (total, record) => total + record.amount);
}

class _FinanceTextField extends StatelessWidget {
  const _FinanceTextField({
    required this.keyValue,
    required this.controller,
    required this.label,
    required this.keyboardType,
  });

  final String keyValue;
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey(keyValue),
      controller: controller,
      keyboardType: keyboardType,
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
