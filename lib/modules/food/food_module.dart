part of '../../main.dart';

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

String _normalizeFoodGroup(String group) {
  return switch (group) {
    '常用' || '常见' || '收藏' || '早餐' || '汤粥' || '家常菜' => '常用',
    '主食' || '主食杂粮' => '主食',
    '蛋白' || '肉蛋奶' || '低脂高蛋白' || '海鲜水产' => '蛋白',
    '蔬果' || '蔬菜水果' => '蔬果',
    '饮品' => '饮品',
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
  String _activeGroup = '常用';
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
      setState(() => _activeGroup = _normalizeFoodGroup('自定义'));
      _openCustomFoodSheet();
      widget.onQuickActionHandled();
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _foodQuery.trim();
    final visibleFoods = _foods.where((food) {
      final groupMatches =
          query.isNotEmpty || _normalizeFoodGroup(food.group) == _activeGroup;
      final queryMatches = query.isEmpty || food.name.contains(query);
      return groupMatches && queryMatches;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _FoodHeader(
                  category: _category,
                  onOpenModules: widget.onOpenModules,
                  onOpenCategories: _openCategorySheet,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: widget.moduleNav,
                ),
                _FoodSearchBar(
                  category: _category,
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
                      150 + _moduleSwitchBarReservedHeight,
                    ),
                    children: [
                      _ModuleLinkedSummaryCard(
                        title: '饮食联动',
                        subtitle: '已记录的摄入会同步到健康、计划和桌面入口。',
                        icon: Icons.restaurant_rounded,
                        values: [
                          ('今日', '$_todayCalories kcal'),
                          ('锻炼', '${widget.workoutGroups} 组'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_activeGroup == '自定义')
                        _FoodAddCustomCard(onTap: _openCustomFoodSheet),
                      if (visibleFoods.isEmpty)
                        _FoodEmptyState(
                          group: _activeGroup,
                          query: query,
                          onAddCustom: _openCustomFoodSheet,
                        )
                      else
                        ...visibleFoods.map((food) {
                          return _FoodCard(
                            food: food,
                            onAdd: () =>
                                setState(() => _selectedFoods.add(food)),
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
                  _FoodTabs(
                    active: _activeGroup,
                    onChanged: (group) => setState(() => _activeGroup = group),
                  ),
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
              _activeGroup = normalizedGroup;
              _foodSearchController.clear();
              _foodQuery = '';
            });
          },
        );
      },
    );
  }
}

class _FoodMealSelector extends StatelessWidget {
  const _FoodMealSelector({
    required this.meals,
    required this.activeMeal,
    required this.caloriesByMeal,
    required this.onChanged,
  });

  final List<String> meals;
  final String activeMeal;
  final Map<String, int> caloriesByMeal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: meals.map((meal) {
          final selected = activeMeal == meal;
          final calories = caloriesByMeal[meal] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              key: ValueKey('food_meal_$meal'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(meal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 88,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.line,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      calories == 0 ? '待记录' : '$calories kcal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.86)
                            : AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FoodCalorieProgressCard extends StatelessWidget {
  const _FoodCalorieProgressCard({
    required this.consumed,
    required this.suggested,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int consumed;
  final int suggested;
  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    final progress = suggested <= 0 ? 0.0 : (consumed / suggested).clamp(0, 1);

    return Container(
      key: const ValueKey('food_calorie_progress_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '今日热量',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$consumed / $suggested kcal',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 10,
              backgroundColor: AppColors.background,
              color: consumed > suggested
                  ? AppColors.financeRed
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FoodMacroPill(
                  label: '蛋白质',
                  value: '${protein.round()}g',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FoodMacroPill(
                  label: '碳水',
                  value: '${carbs.round()}g',
                  color: const Color(0xFFFFA14A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FoodMacroPill(
                  label: '脂肪',
                  value: '${fat.round()}g',
                  color: const Color(0xFFFF7A83),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodMacroPill extends StatelessWidget {
  const _FoodMacroPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodQuickSections extends StatelessWidget {
  const _FoodQuickSections({
    required this.logs,
    required this.templates,
    required this.reminders,
    required this.trend,
    required this.onRepeatLastMeal,
    required this.onUseTemplate,
  });

  final List<FoodLogEntry> logs;
  final List<_FoodMealTemplate> templates;
  final List<String> reminders;
  final List<double> trend;
  final VoidCallback onRepeatLastMeal;
  final ValueChanged<_FoodMealTemplate> onUseTemplate;

  @override
  Widget build(BuildContext context) {
    final frequent = _frequentFoods();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FoodSectionHeader(
          title: '快捷记录',
          actionLabel: logs.isEmpty ? '常吃组合' : '一键再吃',
          onAction: onRepeatLastMeal,
        ),
        const SizedBox(height: 10),
        if (frequent.isEmpty)
          const _FoodInfoBlock(
            icon: Icons.history_rounded,
            title: '常吃食物',
            subtitle: '记录后会自动按出现次数排序。',
          )
        else
          _FoodFrequentBlock(items: frequent),
        const SizedBox(height: 12),
        _FoodTemplateBlock(
          templates: templates,
          onUseTemplate: onUseTemplate,
        ),
        const SizedBox(height: 12),
        _FoodReminderBlock(reminders: reminders),
        const SizedBox(height: 12),
        _FoodTrendBlock(values: trend),
      ],
    );
  }

  List<({String name, int count, int calories})> _frequentFoods() {
    final counts = <String, ({int count, int calories})>{};
    for (final entry in logs) {
      final current = counts[entry.food.name] ?? (count: 0, calories: 0);
      counts[entry.food.name] = (
        count: current.count + 1,
        calories: current.calories + entry.calories,
      );
    }
    final result = counts.entries
        .map(
          (entry) => (
            name: entry.key,
            count: entry.value.count,
            calories: entry.value.calories,
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return result.take(3).toList();
  }
}

class _FoodSectionHeader extends StatelessWidget {
  const _FoodSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          key: const ValueKey('food_repeat_last_meal'),
          onPressed: onAction,
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _FoodInfoBlock extends StatelessWidget {
  const _FoodInfoBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('food_frequent_block'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
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
        ],
      ),
    );
  }
}

class _FoodFrequentBlock extends StatelessWidget {
  const _FoodFrequentBlock({required this.items});

  final List<({String name, int count, int calories})> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '常吃排行',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${item.count} 次 · ${item.calories} kcal',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodTemplateBlock extends StatelessWidget {
  const _FoodTemplateBlock({
    required this.templates,
    required this.onUseTemplate,
  });

  final List<_FoodMealTemplate> templates;
  final ValueChanged<_FoodMealTemplate> onUseTemplate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '餐次模板',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...templates.map(
            (template) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                key: ValueKey('food_template_${template.title}'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => onUseTemplate(template),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(template.icon, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.title,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${template.meal} · ${template.subtitle}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.add_circle_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodReminderBlock extends StatelessWidget {
  const _FoodReminderBlock({required this.reminders});

  final List<String> reminders;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                '饮食提醒',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...reminders.map(
            (reminder) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reminder,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodTrendBlock extends StatelessWidget {
  const _FoodTrendBlock({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final average = values.isEmpty
        ? 0
        : values.fold<double>(0, (sum, value) => sum + value) / values.length;

    return Container(
      key: const ValueKey('food_trend_block'),
      height: 142,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '7 天热量趋势',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '均值 ${average.round()}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CustomPaint(
              painter: _TinyBarsPainter(
                values: values,
                color: AppColors.success,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodHeader extends StatelessWidget {
  const _FoodHeader({
    required this.category,
    required this.onOpenModules,
    required this.onOpenCategories,
  });

  final String category;
  final VoidCallback onOpenModules;
  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    return _ModuleGlassHeader(
      module: LifeModule.food,
      title: '饮食',
      onOpenModules: onOpenModules,
      onOpenMore: onOpenCategories,
    );
  }
}

class _FoodSearchBar extends StatelessWidget {
  const _FoodSearchBar({
    required this.category,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final String category;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: _GlassSurface(
        borderRadius: 16,
        color: AppColors.surface.withValues(alpha: 0.54),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: AppColors.muted, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('food_search_field'),
                  controller: controller,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '请输入食物名称',
                    hintStyle: TextStyle(
                      color: AppColors.muted.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  tooltip: '清空',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.muted,
                    size: 18,
                  ),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodTabs extends StatelessWidget {
  const _FoodTabs({
    required this.active,
    required this.onChanged,
  });

  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const quickGroups = _foodCategories;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: quickGroups.map((group) {
        final selected = active == group;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(group),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: [
                Text(
                  group,
                  style: TextStyle(
                    color: selected ? AppColors.ink : AppColors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: selected ? 20 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FoodAddCustomCard extends StatelessWidget {
  const _FoodAddCustomCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('add_custom_food_button'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '添加自定义食物',
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

class _FoodEmptyState extends StatelessWidget {
  const _FoodEmptyState({
    required this.group,
    required this.query,
    required this.onAddCustom,
  });

  final String group;
  final String query;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    final isCustom = group == '自定义';
    final title = query.isEmpty ? '这里还没有食物' : '没有匹配的食物';
    final subtitle = query.isEmpty ? '添加常吃项后会出现在这里' : '换个关键词试试，或添加为自定义食物';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.muted, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isCustom) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onAddCustom,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '添加自定义食物',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.food,
    required this.onAdd,
  });

  final FoodItem food;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onAdd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB8C0D9).withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(food.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${food.calorie} 千卡 / ${food.unit}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomFoodSheet extends StatefulWidget {
  const _CustomFoodSheet({
    required this.initialName,
    required this.onSave,
  });

  final String initialName;
  final void Function(String name, int calorie, String unit, String group)
      onSave;

  @override
  State<_CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends State<_CustomFoodSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _calorieController;
  late final TextEditingController _unitController;
  String _group = '自定义';
  static const _groups = ['自定义', '常用', '主食', '蛋白', '蔬果', '饮品', '零食', '外卖'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _calorieController = TextEditingController(text: '120');
    _unitController = TextEditingController(text: '1 份');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '自定义食物',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _SheetTextField(
                keyName: 'custom_food_name',
                controller: _nameController,
                label: '食物名称',
                hint: '例如：燕麦酸奶',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SheetTextField(
                      keyName: 'custom_food_calorie',
                      controller: _calorieController,
                      label: '热量',
                      hint: '120',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SheetTextField(
                      keyName: 'custom_food_unit',
                      controller: _unitController,
                      label: '单位',
                      hint: '1 份',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '分类',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _groups.map((group) {
                  final selected = _group == group;
                  return ChoiceChip(
                    key: ValueKey('custom_food_group_$group'),
                    label: Text(group),
                    selected: selected,
                    onSelected: (_) => setState(() => _group = group),
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primary : AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: const ValueKey('save_custom_food_button'),
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();
    final calorie = int.tryParse(_calorieController.text.trim());
    if (name.isEmpty || unit.isEmpty || calorie == null || calorie <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写有效的食物名称、热量和单位'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSave(name, calorie, unit, _group);
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.keyName,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  final String keyName;
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey(keyName),
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FoodSelectedBar extends StatelessWidget {
  const _FoodSelectedBar({
    required this.count,
    required this.calories,
    required this.onRecord,
  });

  final int count;
  final int calories;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        _moduleSwitchBarBottomGap,
      ),
      child: Container(
        key: const ValueKey('food_selected_bar_container'),
        height: 48,
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9FA8C7).withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '已选 $count 项 · $calories 千卡',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              width: 88,
              height: 36,
              child: FilledButton(
                key: const ValueKey('food_record_selected_button'),
                onPressed: onRecord,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '记录',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodCategorySheet extends StatelessWidget {
  const _FoodCategorySheet({
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const sections = [
      (
        '餐饮',
        Icons.restaurant_rounded,
        [
          ('三餐', '🍽️'),
          ('外卖', '🥡'),
          ('饮品', '🧋'),
          ('咖啡', '☕'),
          ('零食饮水', '🧃'),
          ('食材', '🥦'),
          ('烘焙甜品', '🍰'),
          ('酒水', '🍷'),
        ],
      ),
      (
        '交通',
        Icons.directions_car_filled_rounded,
        [
          ('打车', '🚙'),
          ('公共交通', '🚍'),
          ('火车', '🚄'),
          ('机票', '✈️'),
          ('共享单车', '🚲'),
          ('充电', '🔌'),
          ('停车', '🅿️'),
          ('加油', '⛽'),
          ('车辆维护', '🛠️'),
        ],
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const _SheetHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              _IconBubble(
                icon: Icons.close_rounded,
                color: const Color(0xFF9A8FF7),
                onTap: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    '分类',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 42),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: sections.map((section) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModuleSectionTitle(icon: section.$2, title: section.$1),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.08,
                      children: section.$3.map((item) {
                        return _FoodCategoryTile(
                          emoji: item.$2,
                          label: item.$1,
                          selected: selected == item.$1,
                          onTap: () => onSelect(item.$1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCategoryTile extends StatelessWidget {
  const _FoodCategoryTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFE2B853) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
