// 中文注释：业务数据模型，负责 App 内状态、序列化和恢复。

part of 'models.dart';

/// 首页事件流中的一条生活动态（标题、详情、图标和颜色）。
class LifeEvent {
  const LifeEvent({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
}
