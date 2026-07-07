// 中文注释：饮食模块源码，负责食物类目、餐次记录和营养汇总。

part of 'food.dart';

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
        moduleSwitchBarBottomGap,
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

    return InfoSheetFrame(
      title: '分类',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections.map((section) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModuleSectionTitle(icon: section.$2, title: section.$1),
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
      child: GlassSurface(
        borderRadius: 8,
        padding: const EdgeInsets.all(10),
        color: AppColors.surface.withValues(alpha: selected ? 0.92 : 0.72),
        child: AnimatedScale(
          scale: selected ? 0.98 : 1,
          duration: const Duration(milliseconds: 160),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? const Color(0xFF7A5D11) : AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
