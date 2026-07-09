// 中文注释：饮食模块源码，负责食物类目、餐次记录和营养汇总。

part of 'food.dart';

class _FoodMealTemplate {
  const _FoodMealTemplate({
    required this.title,
    required this.meal,
    required this.items,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String meal;
  final List<String> items;
  final String subtitle;
  final IconData icon;
}

const _foodCategories = ['常用', '主食', '蛋白', '蔬果', '饮品', '零食', '外卖', '自定义'];
const _customFoodCategoryLabels = ['主食', '蛋白', '蔬果', '饮品', '零食', '外卖', '自定义'];

String foodMealForTime(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 11) {
    return '早餐';
  }
  if (hour >= 11 && hour < 16) {
    return '午餐';
  }
  if (hour >= 16 && hour < 21) {
    return '晚餐';
  }
  return '夜宵';
}

String _foodCategoryForGroup(String group) {
  return switch (normalizeFoodGroup(group)) {
    '常用' => '常用',
    '主食' => '主食',
    '蛋白' => '蛋白',
    '蔬果' => '蔬果',
    '饮品' => '饮品',
    '零食' => '零食',
    '外卖' => '外卖',
    '自定义' => '自定义',
    _ => '常用',
  };
}

class FoodModulePage extends StatefulWidget {
  const FoodModulePage({
    super.key,
    required this.moduleNav,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.onRecordFoodLogs,
    required this.foodCalories,
    required this.foodLogs,
    required this.workoutGroups,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final Widget moduleNav;
  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final ValueChanged<List<FoodLogEntry>> onRecordFoodLogs;
  final int foodCalories;
  final List<FoodLogEntry> foodLogs;
  final int workoutGroups;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<FoodModulePage> createState() => _FoodModulePageState();
}

class _FoodModulePageState extends State<FoodModulePage> {
  final List<FoodItem> _foods = [
    const FoodItem(
        emoji: '🥗', name: '混合沙拉', calorie: 80, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🍣', name: '三文鱼寿司', calorie: 142, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🥪', name: '三明治', calorie: 250, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🍕', name: '披萨（芝士）', calorie: 266, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🥟', name: '水饺', calorie: 230, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🍱', name: '便当', calorie: 168, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🥯', name: '贝果', calorie: 257, unit: '100 克', group: '早餐'),
    const FoodItem(
        emoji: '🥟', name: '包子', calorie: 227, unit: '100 克', group: '早餐'),
    const FoodItem(
        emoji: '🍳', name: '煎蛋', calorie: 196, unit: '100 克', group: '早餐'),
    const FoodItem(
        emoji: '🥛', name: '豆浆', calorie: 31, unit: '100 毫升', group: '早餐'),
    const FoodItem(
        emoji: '🥣', name: '小米粥', calorie: 46, unit: '100 克', group: '汤粥'),
    const FoodItem(
        emoji: '🍲', name: '皮蛋瘦肉粥', calorie: 75, unit: '100 克', group: '汤粥'),
    const FoodItem(
        emoji: '🍜', name: '番茄蛋汤', calorie: 28, unit: '100 克', group: '汤粥'),
    const FoodItem(
        emoji: '🍚', name: '米饭', calorie: 116, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🍜', name: '面条', calorie: 137, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🍞', name: '全麦面包', calorie: 246, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🌽', name: '玉米', calorie: 112, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🍠', name: '红薯', calorie: 90, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🥣', name: '燕麦片', calorie: 377, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🍚', name: '糙米饭', calorie: 111, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🍜', name: '荞麦面', calorie: 120, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🥔', name: '土豆', calorie: 81, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🌾', name: '藜麦饭', calorie: 120, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🥚', name: '鸡蛋', calorie: 144, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🍗', name: '鸡胸肉', calorie: 133, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🥩', name: '牛肉', calorie: 125, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🥛', name: '纯牛奶', calorie: 54, unit: '100 毫升', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🧀', name: '无糖酸奶', calorie: 72, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🥛', name: '豆腐', calorie: 81, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🍖', name: '猪里脊', calorie: 155, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🍗', name: '鸡腿肉', calorie: 181, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🧀', name: '低脂奶酪', calorie: 180, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🥛', name: '希腊酸奶', calorie: 59, unit: '100 克', group: '低脂高蛋白'),
    const FoodItem(
        emoji: '🍗', name: '即食鸡胸', calorie: 120, unit: '100 克', group: '低脂高蛋白'),
    const FoodItem(
        emoji: '🥚', name: '蛋白', calorie: 60, unit: '100 克', group: '低脂高蛋白'),
    const FoodItem(
        emoji: '🥩', name: '瘦牛肉', calorie: 106, unit: '100 克', group: '低脂高蛋白'),
    const FoodItem(
        emoji: '🐟', name: '鳕鱼', calorie: 88, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🦐', name: '虾仁', calorie: 99, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🦀', name: '蟹肉', calorie: 97, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🦑', name: '鱿鱼', calorie: 75, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🐟', name: '金枪鱼', calorie: 110, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🦪', name: '扇贝', calorie: 69, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🐟', name: '带鱼', calorie: 127, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🥦', name: '西兰花', calorie: 36, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🥬', name: '生菜', calorie: 16, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🍅', name: '番茄', calorie: 15, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🍎', name: '苹果', calorie: 53, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🍌', name: '香蕉', calorie: 93, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🫐', name: '蓝莓', calorie: 57, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🥒', name: '黄瓜', calorie: 16, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🥕', name: '胡萝卜', calorie: 32, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🍓', name: '草莓', calorie: 32, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🥑', name: '牛油果', calorie: 171, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🍛', name: '番茄炒蛋', calorie: 91, unit: '100 克', group: '家常菜'),
    const FoodItem(
        emoji: '🥬', name: '清炒时蔬', calorie: 64, unit: '100 克', group: '家常菜'),
    const FoodItem(
        emoji: '🍗', name: '土豆炖鸡', calorie: 128, unit: '100 克', group: '家常菜'),
    const FoodItem(
        emoji: '🥩', name: '青椒牛肉', calorie: 142, unit: '100 克', group: '家常菜'),
    const FoodItem(
        emoji: '🍔', name: '汉堡', calorie: 256, unit: '100 克', group: '外卖快餐'),
    const FoodItem(
        emoji: '🍟', name: '薯条', calorie: 312, unit: '100 克', group: '外卖快餐'),
    const FoodItem(
        emoji: '🍜', name: '麻辣烫', calorie: 118, unit: '100 克', group: '外卖快餐'),
    const FoodItem(
        emoji: '🍱', name: '盖浇饭', calorie: 164, unit: '100 克', group: '外卖快餐'),
    const FoodItem(
        emoji: '☕', name: '美式咖啡', calorie: 1, unit: '100 毫升', group: '收藏'),
    const FoodItem(
        emoji: '🥤', name: '可乐', calorie: 43, unit: '100 毫升', group: '收藏'),
    const FoodItem(
        emoji: '🍵', name: '无糖绿茶', calorie: 0, unit: '100 毫升', group: '饮品'),
    const FoodItem(
        emoji: '🧋', name: '珍珠奶茶', calorie: 52, unit: '100 毫升', group: '饮品'),
    const FoodItem(
        emoji: '🧃', name: '橙汁', calorie: 45, unit: '100 毫升', group: '饮品'),
    const FoodItem(
        emoji: '🥤', name: '苏打水', calorie: 0, unit: '100 毫升', group: '饮品'),
    const FoodItem(
        emoji: '🥜', name: '坚果', calorie: 607, unit: '100 克', group: '零食'),
    const FoodItem(
        emoji: '🍫', name: '黑巧克力', calorie: 600, unit: '100 克', group: '零食'),
    const FoodItem(
        emoji: '🍪', name: '苏打饼干', calorie: 408, unit: '100 克', group: '零食'),
    const FoodItem(
        emoji: '🍦', name: '冰淇淋', calorie: 207, unit: '100 克', group: '零食'),
    const FoodItem(
        emoji: '🍰', name: '蛋糕', calorie: 347, unit: '100 克', group: '零食'),
    const FoodItem(
        emoji: '🥜', name: '杏仁', calorie: 578, unit: '100 克', group: '坚果种子'),
    const FoodItem(
        emoji: '🌰', name: '核桃', calorie: 646, unit: '100 克', group: '坚果种子'),
    const FoodItem(
        emoji: '🌻', name: '南瓜子', calorie: 559, unit: '100 克', group: '坚果种子'),
    const FoodItem(
        emoji: '🧂', name: '生抽', calorie: 63, unit: '100 毫升', group: '调味酱料'),
    const FoodItem(
        emoji: '🍯', name: '蜂蜜', calorie: 321, unit: '100 克', group: '调味酱料'),
    const FoodItem(
        emoji: '🥫', name: '番茄酱', calorie: 83, unit: '100 克', group: '调味酱料'),
    const FoodItem(
        emoji: '🍵', name: '拿铁咖啡', calorie: 50, unit: '100 毫升', group: '自定义'),
  ];

  final List<FoodItem> _selectedFoods = [];
  final TextEditingController _foodSearchController = TextEditingController();
  String _activeFoodCategory = '常用';
  String _activeMeal = foodMealForTime(DateTime.now());
  String _foodQuery = '';
  int _handledQuickActionToken = 0;
  static const _suggestedCalories = 1800;
  static const _meals = ['早餐', '午餐', '晚餐', '夜宵'];
  static const _mealTemplates = [
    _FoodMealTemplate(
      title: '减脂早餐',
      meal: '早餐',
      items: ['鸡蛋', '全麦面包', '无糖酸奶'],
      subtitle: '高蛋白 · 低负担',
      icon: Icons.wb_sunny_rounded,
    ),
    _FoodMealTemplate(
      title: '工作日午餐',
      meal: '午餐',
      items: ['米饭', '鸡胸肉', '西兰花'],
      subtitle: '主食 + 蛋白 + 蔬菜',
      icon: Icons.work_rounded,
    ),
    _FoodMealTemplate(
      title: '训练后夜宵',
      meal: '夜宵',
      items: ['希腊酸奶', '香蕉'],
      subtitle: '训练后补充',
      icon: Icons.fitness_center_rounded,
    ),
  ];

  int get _totalCalories =>
      _selectedFoods.fold(0, (total, food) => total + food.calorie);

  int get _loggedCalories =>
      _todayLogs.fold(0, (total, entry) => total + entry.calories);

  int get _todayCalories => _loggedCalories;

  double get _todayProtein =>
      _todayLogs.fold(0, (total, entry) => total + entry.protein);

  double get _todayCarbs =>
      _todayLogs.fold(0, (total, entry) => total + entry.carbs);

  double get _todayFat =>
      _todayLogs.fold(0, (total, entry) => total + entry.fat);

  List<FoodLogEntry> get _todayLogs {
    return todayFoodLogs(widget.foodLogs, DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _maybeHandleQuickAction();
  }

  @override
  void didUpdateWidget(covariant FoodModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeHandleQuickAction();
  }

  @override
  void dispose() {
    _foodSearchController.dispose();
    super.dispose();
  }

  void _maybeHandleQuickAction() {
    if (widget.quickAction != WidgetQuickAction.addFood ||
        widget.quickActionToken == _handledQuickActionToken) {
      return;
    }
    _handledQuickActionToken = widget.quickActionToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // 小组件“记饮食”打开自定义食物表单，用户可以马上补名称、热量和份量。
      setState(() => _activeFoodCategory = '自定义');
      _openCustomFoodSheet();
      widget.onQuickActionHandled();
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _foodQuery.trim();
    final visibleFoods = _foods.where((food) {
      final categoryMatches = query.isNotEmpty ||
          _foodCategoryForGroup(food.group) == _activeFoodCategory;
      final queryMatches = query.isEmpty || food.name.contains(query);
      return categoryMatches && queryMatches;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LiquidModuleBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _FoodHeader(
                    onOpenModules: widget.onOpenModules,
                    onOpenTools: _openFoodToolsSheet,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: widget.moduleNav,
                  ),
                  _FoodSearchBar(
                    controller: _foodSearchController,
                    onChanged: (value) => setState(() => _foodQuery = value),
                    onClear: _clearFoodSearch,
                  ),
                  Expanded(
                    child: ListView(
                      key: const ValueKey('food_main_list'),
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        6,
                        18,
                        96,
                      ),
                      children: [
                        _FoodMealSelector(
                          meals: _meals,
                          activeMeal: _activeMeal,
                          caloriesByMeal: _caloriesByMeal(),
                          onChanged: (meal) =>
                              setState(() => _activeMeal = meal),
                        ),
                        const SizedBox(height: 12),
                        _FoodCalorieProgressCard(
                          consumed: _todayCalories,
                          suggested: _suggestedCalories,
                          protein: _todayProtein,
                          carbs: _todayCarbs,
                          fat: _todayFat,
                        ),
                        const SizedBox(height: 10),
                        _FoodCategoryScroller(
                          activeCategory: _activeFoodCategory,
                          onChanged: (category) =>
                              setState(() => _activeFoodCategory = category),
                        ),
                        const SizedBox(height: 12),
                        if (_activeFoodCategory == '自定义')
                          _FoodAddCustomCard(onTap: _openCustomFoodSheet),
                        if (visibleFoods.isEmpty)
                          _FoodEmptyState(
                            category: _activeFoodCategory,
                            query: query,
                            onAddCustom: _openCustomFoodSheet,
                          )
                        else
                          ...visibleFoods.map((food) {
                            return _FoodCard(
                              food: food,
                              selectedCount: _selectedCountFor(food),
                              onAdd: () => _addSelectedFood(food),
                              onRemove: () => _removeSelectedFood(food),
                            );
                          }),
                        const SizedBox(height: 2),
                        _FoodQuickSections(
                          logs: _todayLogs,
                          templates: _mealTemplates,
                          reminders: _foodReminders(),
                          trend: _foodTrendValues(),
                          onRepeatLastMeal: _repeatLastMeal,
                          onUseTemplate: _useMealTemplate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FoodSelectedBar(
                      count: _selectedFoods.length,
                      calories: _totalCalories,
                      onRecord: _recordFoods,
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

  void _clearFoodSearch() {
    _foodSearchController.clear();
    setState(() => _foodQuery = '');
  }

  int _selectedCountFor(FoodItem food) {
    return _selectedFoods.where((item) => item.name == food.name).length;
  }

  void _addSelectedFood(FoodItem food) {
    setState(() => _selectedFoods.add(food));
  }

  void _removeSelectedFood(FoodItem food) {
    final index = _selectedFoods.indexWhere((item) => item.name == food.name);
    if (index == -1) {
      return;
    }
    setState(() => _selectedFoods.removeAt(index));
  }

  Map<String, int> _caloriesByMeal() {
    return {
      for (final meal in _meals)
        meal: _todayLogs
            .where((entry) => entry.meal == meal)
            .fold(0, (total, entry) => total + entry.calories),
    };
  }

  List<String> _foodReminders() {
    final reminders = <String>[];
    final mealsRecorded = _todayLogs.map((entry) => entry.meal).toSet();
    if (!mealsRecorded.contains('晚餐') && DateTime.now().hour >= 18) {
      reminders.add('晚餐还没有记录');
    }
    if (_todayCalories > _suggestedCalories) {
      reminders.add('今日摄入已高于建议');
    }
    if (widget.workoutGroups > 0 && !mealsRecorded.contains('夜宵')) {
      reminders.add('训练后可以记录一次夜宵');
    }
    if (reminders.isEmpty) {
      reminders.add(_todayLogs.isEmpty ? '先把最近一餐记下来' : '今天饮食节奏正常');
    }
    return reminders;
  }

  List<double> _foodTrendValues() {
    final today = _todayCalories.toDouble();
    return [1520, 1680, 1440, 1880, 1610, 1730, today];
  }

  void _repeatLastMeal() {
    final recent = _todayLogs.reversed
        .where((entry) => entry.meal == _activeMeal)
        .map((entry) => entry.food.name)
        .toSet()
        .toList();
    final names = recent.isEmpty
        ? (_activeMeal == '早餐' ? ['鸡蛋', '全麦面包', '纯牛奶'] : ['米饭', '鸡胸肉', '西兰花'])
        : recent;
    _selectFoodsByNames(names, _activeMeal);
  }

  void _useMealTemplate(_FoodMealTemplate template) {
    _selectFoodsByNames(template.items, template.meal);
  }

  void _selectFoodsByNames(List<String> names, String meal) {
    final foods = names.map(_findFoodByName).whereType<FoodItem>().toList();
    if (foods.isEmpty) {
      return;
    }
    _recordFoodItems(foods, meal);
  }

  FoodItem? _findFoodByName(String name) {
    for (final food in _foods) {
      if (food.name == name) {
        return food;
      }
    }
    return null;
  }

  void _recordFoods() {
    if (_selectedFoods.isEmpty) {
      return;
    }
    _recordFoodItems(List.of(_selectedFoods), _activeMeal);
    setState(_selectedFoods.clear);
  }

  void _recordFoodItems(List<FoodItem> foods, String meal) {
    final calories = foods.fold(0, (total, food) => total + food.calorie);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已记录 $meal ${foods.length} 项，$calories 千卡'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    final now = DateTime.now();
    final entries = foods
        .map(
          (food) => FoodLogEntry(
            food: food,
            meal: meal,
            servings: 1,
            note: '',
            recordedAt: now,
          ),
        )
        .toList();
    widget.onRecordFoodLogs(entries);
    setState(() => _activeMeal = meal);
  }

  void _openFoodToolsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _FoodToolsSheet(
          selectedCount: _selectedFoods.length,
          todayCalories: _todayCalories,
          suggestedCalories: _suggestedCalories,
          protein: _todayProtein,
          carbs: _todayCarbs,
          fat: _todayFat,
          activeMeal: _activeMeal,
          onAddCustomFood: () =>
              _closeSheetAndRun(sheetContext, _openCustomFoodSheet),
          onRepeatLastMeal: () =>
              _closeSheetAndRun(sheetContext, _repeatLastMeal),
          onShowTodayLogs: () =>
              _closeSheetAndRun(sheetContext, _openTodayFoodLogsSheet),
          onClearSelected: _selectedFoods.isEmpty
              ? null
              : () => _closeSheetAndRun(sheetContext, () {
                    setState(_selectedFoods.clear);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已清空当前已选食物'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }),
        );
      },
    );
  }

  void _closeSheetAndRun(BuildContext sheetContext, VoidCallback action) {
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        action();
      }
    });
  }

  void _openTodayFoodLogsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FoodTodayLogsSheet(logs: _todayLogs),
    );
  }

  void _openCustomFoodSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CustomFoodSheet(
          initialName: _foodQuery.trim(),
          initialCategory:
              _activeFoodCategory == '常用' ? '自定义' : _activeFoodCategory,
          onSave: (name, calorie, unit, group) {
            Navigator.of(context).pop();
            setState(() {
              final normalizedGroup = normalizeFoodGroup(group);
              _foods.add(
                FoodItem(
                  emoji: '🍱',
                  name: name,
                  calorie: calorie,
                  unit: unit,
                  group: normalizedGroup,
                ),
              );
              _activeFoodCategory = _foodCategoryForGroup(normalizedGroup);
              _foodSearchController.clear();
              _foodQuery = '';
            });
          },
        );
      },
    );
  }
}
