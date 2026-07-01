# 饮食类目重构实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 将饮食模块从“餐次、食物类型、收藏/自定义混排”的入口，重构为餐次和食物类目分离的记录体验。

**架构：** 第一版仍保留单文件 `lib/modules/food/food_module.dart`，避免把 UI 重构和文件拆分混在一起。新增私有类目元数据和规范化 helper，复用现有 `FoodItem.group` 字段承载食物类目；widget 测试先改为覆盖新交互，再写最少实现让测试通过。

**技术栈：** Flutter、Dart、现有 `PingShengApp` widget 测试、Material Icons、现有 `AppColors` 和模块页样式。

---

## 文件结构

- 修改：`lib/modules/food/food_module.dart`
  - 职责：规范食物类目数据；把底部“常见/收藏/自定义”改成内容区横向类目；让餐次选择和食物类目选择分离；更新自定义食物归类逻辑。
- 修改：`test/widget_test.dart`
  - 职责：替换旧饮食类目断言，覆盖新类目切换、跨类目搜索、自定义食物、餐次模板和营养汇总。

## 任务 1：先更新饮食类目测试

**文件：**
- 修改：`test/widget_test.dart`

- [ ] **步骤 1：替换旧类目断言**

在 `food search filters items and custom food can be added` 测试中，删除旧断言：

```dart
expect(find.byKey(const ValueKey('food_group_scroller')), findsNothing);
expect(find.byKey(const ValueKey('food_group_早餐')), findsNothing);
expect(find.byKey(const ValueKey('food_group_主食杂粮')), findsNothing);
expect(find.text('混合沙拉'), findsOneWidget);
```

替换为：

```dart
expect(find.byKey(const ValueKey('food_category_scroller')), findsOneWidget);
expect(find.byKey(const ValueKey('food_category_常用')), findsOneWidget);
expect(find.byKey(const ValueKey('food_category_主食')), findsOneWidget);
expect(find.byKey(const ValueKey('food_category_蛋白')), findsOneWidget);
expect(find.byKey(const ValueKey('food_category_蔬果')), findsOneWidget);
expect(find.byKey(const ValueKey('food_category_饮品')), findsOneWidget);
expect(find.byKey(const ValueKey('food_category_自定义')), findsOneWidget);
expect(find.text('混合沙拉'), findsOneWidget);
```

- [ ] **步骤 2：替换收藏类目流程**

在同一个测试中，删除：

```dart
await tester.tap(find.text('收藏').first);
await tester.pumpAndSettle();
expect(find.text('美式咖啡'), findsOneWidget);
expect(find.text('混合沙拉'), findsNothing);

await tester.tap(find.text('常见').first);
await tester.pumpAndSettle();
```

替换为：

```dart
await tester.tap(find.byKey(const ValueKey('food_category_饮品')));
await tester.pumpAndSettle();
expect(find.text('美式咖啡'), findsOneWidget);
expect(find.text('珍珠奶茶'), findsOneWidget);
expect(find.text('鸡胸肉'), findsNothing);

await tester.tap(find.byKey(const ValueKey('food_category_常用')));
await tester.pumpAndSettle();
```

- [ ] **步骤 3：替换自定义类目入口**

在同一个测试中，删除：

```dart
await tester.tap(find.text('自定义').first);
```

替换为：

```dart
await tester.tap(find.byKey(const ValueKey('food_category_自定义')));
```

- [ ] **步骤 4：新增主食和蛋白类目断言**

在同一个测试中，`鸡胸肉` 搜索断言之后、搜索 `披萨` 之前加入：

```dart
await tester.enterText(find.byKey(const ValueKey('food_search_field')), '');
await tester.pumpAndSettle();

await tester.tap(find.byKey(const ValueKey('food_category_主食')));
await tester.pumpAndSettle();
expect(find.text('米饭'), findsOneWidget);
expect(find.text('鸡胸肉'), findsNothing);

await tester.tap(find.byKey(const ValueKey('food_category_蛋白')));
await tester.pumpAndSettle();
expect(find.text('鸡胸肉'), findsOneWidget);
expect(find.text('米饭'), findsNothing);
```

- [ ] **步骤 5：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "food search filters items and custom food can be added"
```

预期：失败，原因包含找不到 `food_category_scroller` 或 `food_category_主食`。

- [ ] **步骤 6：Commit 测试变更**

```powershell
git add test/widget_test.dart
git commit -m "test: cover food category redesign"
```

## 任务 2：规范食物类目数据和筛选逻辑

**文件：**
- 修改：`lib/modules/food/food_module.dart`

- [ ] **步骤 1：新增类目元数据**

在 `_FoodModulePageState` 前新增：

```dart
class _FoodCategory {
  const _FoodCategory({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

const _foodCategories = [
  _FoodCategory(label: '常用', icon: Icons.auto_awesome_rounded),
  _FoodCategory(label: '主食', icon: Icons.rice_bowl_rounded),
  _FoodCategory(label: '蛋白', icon: Icons.egg_alt_rounded),
  _FoodCategory(label: '蔬果', icon: Icons.eco_rounded),
  _FoodCategory(label: '饮品', icon: Icons.local_cafe_rounded),
  _FoodCategory(label: '零食', icon: Icons.cookie_rounded),
  _FoodCategory(label: '外卖', icon: Icons.takeout_dining_rounded),
  _FoodCategory(label: '自定义', icon: Icons.edit_note_rounded),
];

const _customFoodCategoryLabels = ['主食', '蛋白', '蔬果', '饮品', '零食', '外卖', '自定义'];
```

- [ ] **步骤 2：新增类目规范化 helper**

在 `_foodMacro` 后新增：

```dart
String _foodCategoryForGroup(String group) {
  return switch (group) {
    '常用' || '常见' || '家常菜' => '常用',
    '早餐' || '汤粥' || '主食杂粮' => '主食',
    '肉蛋奶' || '低脂高蛋白' || '海鲜水产' => '蛋白',
    '蔬菜水果' => '蔬果',
    '收藏' || '咖啡' || '饮品' => '饮品',
    '零食' || '坚果种子' || '烘焙甜品' || '调味酱料' => '零食',
    '外卖快餐' || '外卖' => '外卖',
    '自定义' => '自定义',
    _ => '常用',
  };
}
```

- [ ] **步骤 3：更新状态字段**

把：

```dart
String _activeGroup = '常见';
String _category = '三餐';
```

改为：

```dart
String _activeFoodCategory = '常用';
```

删除 `_category` 字段。

- [ ] **步骤 4：更新筛选逻辑**

把 `visibleFoods` 的 group 判断改为：

```dart
final visibleFoods = _foods.where((food) {
  final category = _foodCategoryForGroup(food.group);
  final categoryMatches = query.isNotEmpty || category == _activeFoodCategory;
  final queryMatches = query.isEmpty || food.name.contains(query);
  return categoryMatches && queryMatches;
}).toList();
```

- [ ] **步骤 5：更新快速动作和自定义保存逻辑**

把小组件快捷入口里的：

```dart
setState(() => _activeGroup = '自定义');
```

改为：

```dart
setState(() => _activeFoodCategory = '自定义');
```

把自定义保存后的：

```dart
_activeGroup = _tabForFoodGroup(group);
```

改为：

```dart
_activeFoodCategory = _foodCategoryForGroup(group);
```

删除 `_tabForFoodGroup` 方法。

- [ ] **步骤 6：运行测试验证当前失败收窄**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "food search filters items and custom food can be added"
```

预期：仍失败，但不再因为 `_activeGroup` 或 `_tabForFoodGroup` 未定义而编译失败；失败点应集中在 UI 还没有 `food_category_scroller`。

## 任务 3：重做饮食页类目 UI

**文件：**
- 修改：`lib/modules/food/food_module.dart`

- [ ] **步骤 1：简化搜索框参数**

把 `_FoodSearchBar` 构造函数里的 `category` 参数移除：

```dart
const _FoodSearchBar({
  required this.controller,
  required this.onChanged,
  required this.onClear,
});
```

删除搜索框右侧展示 `category` 的 `Container`。保留搜索、输入框和清空按钮。

- [ ] **步骤 2：更新 build 调用**

把：

```dart
_FoodSearchBar(
  category: _category,
  controller: _foodSearchController,
  onChanged: (value) => setState(() => _foodQuery = value),
  onClear: _clearFoodSearch,
),
```

改为：

```dart
_FoodSearchBar(
  controller: _foodSearchController,
  onChanged: (value) => setState(() => _foodQuery = value),
  onClear: _clearFoodSearch,
),
_FoodCategoryScroller(
  categories: _foodCategories,
  active: _activeFoodCategory,
  onChanged: (category) => setState(() => _activeFoodCategory = category),
),
```

- [ ] **步骤 3：替换自定义入口和空状态调用**

把：

```dart
if (_activeGroup == '自定义')
  _FoodAddCustomCard(onTap: _openCustomFoodSheet),
if (visibleFoods.isEmpty)
  _FoodEmptyState(
    group: _activeGroup,
    query: query,
    onAddCustom: _openCustomFoodSheet,
  )
```

改为：

```dart
if (_activeFoodCategory == '自定义')
  _FoodAddCustomCard(onTap: _openCustomFoodSheet),
if (visibleFoods.isEmpty)
  _FoodEmptyState(
    category: _activeFoodCategory,
    query: query,
    onAddCustom: _openCustomFoodSheet,
  )
```

- [ ] **步骤 4：删除底部 `_FoodTabs` 调用**

把底部 `Column` 中的 `_FoodTabs(...)` 删除，只保留 `_FoodSelectedBar(...)`。

- [ ] **步骤 5：新增 `_FoodCategoryScroller`**

用下列 widget 替换原 `_FoodTabs` 类：

```dart
class _FoodCategoryScroller extends StatelessWidget {
  const _FoodCategoryScroller({
    required this.categories,
    required this.active,
    required this.onChanged,
  });

  final List<_FoodCategory> categories;
  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('food_category_scroller'),
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = active == category.label;
          return ChoiceChip(
            key: ValueKey('food_category_${category.label}'),
            avatar: Icon(
              category.icon,
              size: 16,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            label: Text(category.label),
            selected: selected,
            onSelected: (_) => onChanged(category.label),
            selectedColor: AppColors.primarySoft,
            backgroundColor: AppColors.surface.withValues(alpha: 0.76),
            labelStyle: TextStyle(
              color: selected ? AppColors.primary : AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.24)
                    : AppColors.line,
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}
```

- [ ] **步骤 6：更新 `_FoodEmptyState` 字段名**

把 `_FoodEmptyState` 的 `group` 字段改为 `category`，并把：

```dart
final isCustom = group == '自定义';
```

改为：

```dart
final isCustom = category == '自定义' || query.isNotEmpty;
```

- [ ] **步骤 7：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "food search filters items and custom food can be added"
```

预期：PASS。

- [ ] **步骤 8：Commit UI 和筛选实现**

```powershell
git add lib/modules/food/food_module.dart test/widget_test.dart
git commit -m "feat: separate food meals and categories"
```

## 任务 4：更新自定义食物分类 Sheet

**文件：**
- 修改：`lib/modules/food/food_module.dart`
- 修改：`test/widget_test.dart`

- [ ] **步骤 1：补充自定义类目测试**

在 `food search filters items and custom food can be added` 测试中，打开自定义食物 Sheet 后、保存前加入：

```dart
expect(find.byKey(const ValueKey('custom_food_group_主食')), findsOneWidget);
expect(find.byKey(const ValueKey('custom_food_group_蛋白')), findsOneWidget);
expect(find.byKey(const ValueKey('custom_food_group_蔬果')), findsOneWidget);
expect(find.byKey(const ValueKey('custom_food_group_自定义')), findsOneWidget);
expect(find.byKey(const ValueKey('custom_food_group_主食杂粮')), findsNothing);
expect(find.byKey(const ValueKey('custom_food_group_肉蛋奶')), findsNothing);
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "food search filters items and custom food can be added"
```

预期：失败，原因包含仍找到旧 `custom_food_group_主食杂粮` 或找不到新 `custom_food_group_主食`。

- [ ] **步骤 3：给自定义 Sheet 增加初始类目**

把 `_CustomFoodSheet` 构造函数改为：

```dart
const _CustomFoodSheet({
  required this.initialName,
  required this.initialCategory,
  required this.onSave,
});

final String initialName;
final String initialCategory;
```

在 `_openCustomFoodSheet` 中调用时传入：

```dart
initialCategory:
    _activeFoodCategory == '常用' ? '自定义' : _activeFoodCategory,
```

- [ ] **步骤 4：替换 Sheet 内类目列表**

把 `_CustomFoodSheetState` 中：

```dart
String _group = '自定义';
static const _groups = ['自定义', '主食杂粮', '肉蛋奶', '蔬菜水果', '饮品', '零食', '外卖快餐'];
```

改为：

```dart
late String _group;
```

在 `initState` 中加入：

```dart
_group = _customFoodCategoryLabels.contains(widget.initialCategory)
    ? widget.initialCategory
    : '自定义';
```

把 `Wrap` 的数据源从 `_groups` 改为 `_customFoodCategoryLabels`。

- [ ] **步骤 5：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "food search filters items and custom food can be added"
```

预期：PASS。

- [ ] **步骤 6：Commit 自定义食物分类**

```powershell
git add lib/modules/food/food_module.dart test/widget_test.dart
git commit -m "feat: align custom foods with food categories"
```

## 任务 5：确认餐次模板和营养汇总没有回归

**文件：**
- 修改：`test/widget_test.dart`
- 修改：`lib/modules/food/food_module.dart`

- [ ] **步骤 1：运行现有模板测试**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "food templates and meal summary update nutrition view"
```

预期：PASS。

- [ ] **步骤 2：如果测试因为滚动路径失败，调整测试清空搜索后的状态**

如果失败原因是模板卡片在搜索 `zzz` 后更难滚动定位，把测试里搜索 `zzz` 之后保留，因为这是空状态覆盖；然后确保 `_FoodEmptyState` 在搜索为空时不会阻挡后续列表内容。不要删除模板流程断言。

- [ ] **步骤 3：运行饮食相关测试组**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "food search filters items and custom food can be added"
flutter test test/widget_test.dart --plain-name "food templates and meal summary update nutrition view"
```

预期：两个命令均 PASS。

- [ ] **步骤 4：Commit 回归修正**

如果步骤 2 修改了代码或测试，运行：

```powershell
git add lib/modules/food/food_module.dart test/widget_test.dart
git commit -m "test: keep food meal summaries covered"
```

如果没有修改，跳过 commit。

## 任务 6：最终验证

**文件：**
- 修改：无，除非验证暴露编译问题。

- [ ] **步骤 1：运行 Flutter analyze**

运行：

```powershell
flutter analyze
```

预期：无新增 error。当前工作区已有历史改动时，如果 analyze 报错，先判断是否来自本次饮食类目改动；只修本次改动造成的问题。

- [ ] **步骤 2：运行饮食测试**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "food search filters items and custom food can be added"
flutter test test/widget_test.dart --plain-name "food templates and meal summary update nutrition view"
```

预期：两个命令均 PASS。

- [ ] **步骤 3：检查 diff 范围**

运行：

```powershell
git diff --stat
git diff -- lib/modules/food/food_module.dart test/widget_test.dart
```

预期：本次实现只涉及饮食模块和 widget 测试。不要提交当前工作区里已有的其他模块改动。

- [ ] **步骤 4：提交最终收尾**

如果任务 6 中有修正，运行：

```powershell
git add lib/modules/food/food_module.dart test/widget_test.dart
git commit -m "fix: verify food category redesign"
```

如果任务 6 没有修正，跳过 commit。

## 提交边界说明

当前工作区可能已经存在其它模块的历史修改。执行本计划时，每次 `git add` 都必须只暂存本任务涉及的 hunks；如果 `test/widget_test.dart` 或 `lib/modules/food/food_module.dart` 里已有无关修改，使用 `git diff` 先核对，再用交互式暂存或精确 patch 暂存，不能把无关模块改动带进饮食类目提交。
