part of 'food.dart';

class FoodItem {
  const FoodItem({
    required this.emoji,
    required this.name,
    required this.calorie,
    required this.unit,
    required this.group,
    this.protein,
    this.carbs,
    this.fat,
  });

  final String emoji;
  final String name;
  final int calorie;
  final String unit;
  final String group;
  final double? protein;
  final double? carbs;
  final double? fat;
}

class FoodLogEntry {
  const FoodLogEntry({
    required this.food,
    required this.meal,
    required this.servings,
    required this.note,
    required this.recordedAt,
  });

  final FoodItem food;
  final String meal;
  final double servings;
  final String note;
  final DateTime recordedAt;

  int get calories => (food.calorie * servings).round();
  double get protein => _foodMacro(food, _FoodMacro.protein) * servings;
  double get carbs => _foodMacro(food, _FoodMacro.carbs) * servings;
  double get fat => _foodMacro(food, _FoodMacro.fat) * servings;
}

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

enum _FoodMacro { protein, carbs, fat }

const _foodCategories = ['常用', '主食', '蛋白', '蔬果', '饮品', '零食', '外卖', '自定义'];
const _customFoodCategoryLabels = ['主食', '蛋白', '蔬果', '饮品', '零食', '外卖', '自定义'];

String _foodCategoryForGroup(String group) {
  return switch (_normalizeFoodGroup(group)) {
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

String _normalizeFoodGroup(String group) {
  return switch (group) {
    '常用' || '常见' || '早餐' || '汤粥' || '家常菜' => '常用',
    '主食' || '主食杂粮' => '主食',
    '蛋白' || '肉蛋奶' || '低脂高蛋白' || '海鲜水产' => '蛋白',
    '蔬果' || '蔬菜水果' => '蔬果',
    '收藏' || '饮品' => '饮品',
    '零食' || '坚果种子' || '烘焙甜品' || '调味酱料' => '零食',
    '外卖' || '外卖快餐' => '外卖',
    '自定义' => '自定义',
    _ => '自定义',
  };
}

double _foodMacro(FoodItem food, _FoodMacro macro) {
  final direct = switch (macro) {
    _FoodMacro.protein => food.protein,
    _FoodMacro.carbs => food.carbs,
    _FoodMacro.fat => food.fat,
  };
  if (direct != null) {
    return direct;
  }

  final ratios = switch (_normalizeFoodGroup(food.group)) {
    '蛋白' => (0.22, 0.06, 0.06),
    '主食' => (0.05, 0.20, 0.02),
    '蔬果' => (0.03, 0.12, 0.01),
    '饮品' => (0.02, 0.10, 0.01),
    '零食' => (0.08, 0.28, 0.12),
    _ => (0.10, 0.18, 0.07),
  };
  final ratio = switch (macro) {
    _FoodMacro.protein => ratios.$1,
    _FoodMacro.carbs => ratios.$2,
    _FoodMacro.fat => ratios.$3,
  };
  return food.calorie * ratio;
}

class FoodModulePage extends StatefulWidget {
  const FoodModulePage({
    super.key,
    required this.moduleNav,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.onRecordCalories,
    required this.foodCalories,
    required this.workoutGroups,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final Widget moduleNav;
  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final ValueChanged<int> onRecordCalories;
  final int foodCalories;
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
  final List<FoodLogEntry> _foodLogs = [];
  final TextEditingController _foodSearchController = TextEditingController();
  String _activeFoodCategory = '常用';
  String _category = '三餐';
  String _activeMeal = '午餐';
  String _foodQuery = '';
  int _handledQuickActionToken = 0;
  static const _suggestedCalories = 1800;
  static const _meals = ['早餐', '午餐', '晚餐', '加餐'];
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
      title: '训练后加餐',
      meal: '加餐',
      items: ['希腊酸奶', '香蕉'],
      subtitle: '训练后补充',
      icon: Icons.fitness_center_rounded,
    ),
  ];

  int get _totalCalories =>
      _selectedFoods.fold(0, (total, food) => total + food.calorie);

  int get _loggedCalories =>
      _foodLogs.fold(0, (total, entry) => total + entry.calories);

  int get _todayCalories => math.max(widget.foodCalories, _loggedCalories);

  double get _todayProtein =>
      _foodLogs.fold(0, (total, entry) => total + entry.protein);

  double get _todayCarbs =>
      _foodLogs.fold(0, (total, entry) => total + entry.carbs);

  double get _todayFat =>
      _foodLogs.fold(0, (total, entry) => total + entry.fat);

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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _FoodHeader(
                  onOpenModules: widget.onOpenModules,
                  onOpenCategories: _openCategorySheet,
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
                      150 + moduleSwitchBarReservedHeight,
                    ),
                    children: [
                      ModuleLinkedSummaryCard(
                        title: '饮食联动',
                        subtitle: '已记录的摄入会同步到健康、计划和桌面入口。',
                        icon: Icons.restaurant_rounded,
                        values: [
                          ('今日', '$_todayCalories kcal'),
                          ('锻炼', '${widget.workoutGroups} 组'),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                      _FoodMealSelector(
                        meals: _meals,
                        activeMeal: _activeMeal,
                        caloriesByMeal: _caloriesByMeal(),
                        onChanged: (meal) => setState(() => _activeMeal = meal),
                      ),
                      const SizedBox(height: 12),
                      _FoodCalorieProgressCard(
                        consumed: _todayCalories,
                        suggested: _suggestedCalories,
                        protein: _todayProtein,
                        carbs: _todayCarbs,
                        fat: _todayFat,
                      ),
                      const SizedBox(height: 12),
                      _FoodQuickSections(
                        logs: _foodLogs,
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
        meal: _foodLogs
            .where((entry) => entry.meal == meal)
            .fold(0, (total, entry) => total + entry.calories),
    };
  }

  List<String> _foodReminders() {
    final reminders = <String>[];
    final mealsRecorded = _foodLogs.map((entry) => entry.meal).toSet();
    if (!mealsRecorded.contains('晚餐') && DateTime.now().hour >= 18) {
      reminders.add('晚餐还没有记录');
    }
    if (_todayCalories > _suggestedCalories) {
      reminders.add('今日摄入已高于建议');
    }
    if (widget.workoutGroups > 0 && !mealsRecorded.contains('加餐')) {
      reminders.add('训练后可以记录一次加餐');
    }
    if (reminders.isEmpty) {
      reminders.add(_foodLogs.isEmpty ? '先把最近一餐记下来' : '今天饮食节奏正常');
    }
    return reminders;
  }

  List<double> _foodTrendValues() {
    final today = _todayCalories.toDouble();
    return [1520, 1680, 1440, 1880, 1610, 1730, today];
  }

  void _repeatLastMeal() {
    final recent = _foodLogs.reversed
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
    widget.onRecordCalories(calories);
    setState(() {
      _activeMeal = meal;
      _foodLogs.addAll(
        foods.map(
          (food) => FoodLogEntry(
            food: food,
            meal: meal,
            servings: 1,
            note: '',
            recordedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  void _openCategorySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FoodCategorySheet(
          selected: _category,
          onSelect: (category) {
            Navigator.of(context).pop();
            setState(() => _category = category);
          },
        );
      },
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
              final normalizedGroup = _normalizeFoodGroup(group);
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
