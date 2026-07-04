// 中文注释：业务数据模型，负责 App 内状态、序列化和恢复。

part of 'models.dart';

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
