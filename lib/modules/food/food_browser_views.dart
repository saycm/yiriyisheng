// 中文注释：饮食模块源码，负责食物类目、餐次记录和营养汇总。

part of 'food.dart';

class _FoodHeader extends StatelessWidget {
  const _FoodHeader({
    required this.onOpenModules,
    required this.onOpenCategories,
  });

  final VoidCallback onOpenModules;
  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    return ModuleGlassHeader(
      module: LifeModule.food,
      title: '饮食',
      onOpenModules: onOpenModules,
      onOpenMore: onOpenCategories,
    );
  }
}

class _FoodSearchBar extends StatelessWidget {
  const _FoodSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: GlassSurface(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodCategoryScroller extends StatelessWidget {
  const _FoodCategoryScroller({
    required this.activeCategory,
    required this.onChanged,
  });

  final String activeCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Scrollable(
        key: const ValueKey('food_category_scroller'),
        axisDirection: AxisDirection.right,
        physics: const BouncingScrollPhysics(),
        viewportBuilder: (context, position) {
          return Viewport(
            axisDirection: AxisDirection.right,
            offset: position,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: _foodCategories.map((category) {
                      final selected = activeCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          key: ValueKey('food_category_$category'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => onChanged(category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primarySoft
                                  : AppColors.surface.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary.withValues(alpha: 0.25)
                                    : AppColors.line,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
    required this.category,
    required this.query,
    required this.onAddCustom,
  });

  final String category;
  final String query;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    final showAddCustom = category == '自定义';
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
          if (showAddCustom) ...[
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
    required this.selectedCount,
    required this.onAdd,
    required this.onRemove,
  });

  final FoodItem food;
  final int selectedCount;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

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
            _FoodQuantityControl(
              foodName: food.name,
              count: selectedCount,
              onAdd: onAdd,
              onRemove: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodQuantityControl extends StatelessWidget {
  const _FoodQuantityControl({
    required this.foodName,
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });

  final String foodName;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return _FoodRoundAction(
        keyValue: 'food_add_$foodName',
        icon: Icons.add,
        color: AppColors.primary,
        foregroundColor: Colors.white,
        onTap: onAdd,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FoodRoundAction(
            keyValue: 'food_remove_$foodName',
            icon: Icons.remove,
            color: Colors.white,
            foregroundColor: AppColors.primary,
            onTap: onRemove,
          ),
          SizedBox(
            key: ValueKey('food_selected_count_$foodName'),
            width: 22,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _FoodRoundAction(
            keyValue: 'food_add_$foodName',
            icon: Icons.add,
            color: AppColors.primary,
            foregroundColor: Colors.white,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _FoodRoundAction extends StatelessWidget {
  const _FoodRoundAction({
    required this.keyValue,
    required this.icon,
    required this.color,
    required this.foregroundColor,
    required this.onTap,
  });

  final String keyValue;
  final IconData icon;
  final Color color;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey(keyValue),
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: foregroundColor, size: 20),
      ),
    );
  }
}
