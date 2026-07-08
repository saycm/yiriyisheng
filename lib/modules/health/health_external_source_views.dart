// 中文注释：健康外部数据源页面，负责展示 Health Connect 和手机传感器连接状态。

part of 'health.dart';

class _HealthSensorCard extends StatelessWidget {
  const _HealthSensorCard({required this.snapshot});

  final HealthSensorSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    // 传感器数据是辅助信息，缺失时显示能力状态，不把空值当成 0。
    final values = [
      (
        '今日步数',
        snapshot.stepCounterToday == null
            ? (snapshot.stepCounterAvailable ? '可用' : '无')
            : '${_formatSensorSteps(snapshot.stepCounterToday!)} 步'
      ),
      (
        '心率',
        snapshot.heartRateBpm == null
            ? (snapshot.heartRateSensorAvailable ? '待读取' : '无')
            : '${snapshot.heartRateBpm!.round()} bpm'
      ),
      (
        '加速度',
        snapshot.accelerationMagnitude == null
            ? (snapshot.accelerometerAvailable ? '可用' : '无')
            : snapshot.accelerationMagnitude!.toStringAsFixed(1)
      ),
    ];
    return ModuleLinkedSummaryCard(
      title: '手机传感器',
      subtitle: '来自系统 SensorManager 的实时设备能力和读数。',
      icon: Icons.sensors_rounded,
      values: values,
    );
  }

  String _formatSensorSteps(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}

class _HealthExternalSourceEntry extends StatelessWidget {
  const _HealthExternalSourceEntry({
    required this.snapshot,
    required this.loading,
    required this.onTap,
  });

  final HealthSystemSnapshot snapshot;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = _HealthConnectionState.fromSnapshot(snapshot, loading);

    return KeyedSubtree(
      key: const ValueKey('health_external_source_entry'),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.78),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: state.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.sync_alt_rounded, color: state.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '外部数据源',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Health Connect 是可选数据源，不影响状态中心。',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthExternalSourceSheet extends StatefulWidget {
  const _HealthExternalSourceSheet({
    required this.snapshot,
    required this.loading,
    required this.onRefreshSnapshot,
    required this.onRequestPermissionAndRefresh,
    required this.onOpenSettings,
  });

  final HealthSystemSnapshot snapshot;
  final bool loading;
  final Future<HealthSystemSnapshot> Function() onRefreshSnapshot;
  final Future<HealthSystemSnapshot> Function() onRequestPermissionAndRefresh;
  final VoidCallback onOpenSettings;

  @override
  State<_HealthExternalSourceSheet> createState() =>
      _HealthExternalSourceSheetState();
}

class _HealthExternalSourceSheetState
    extends State<_HealthExternalSourceSheet> {
  late HealthSystemSnapshot _snapshot = widget.snapshot;
  late bool _loading = widget.loading;

  @override
  void initState() {
    super.initState();
    if (widget.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _refresh();
      });
    }
  }

  Future<void> _refresh() async {
    // 弹层内刷新只更新本地快照，不直接修改健康状态中心的主观记录。
    setState(() => _loading = true);
    final snapshot = await widget.onRefreshSnapshot();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<void> _requestPermission() async {
    // 授权后立即重新读取，用户能看到权限变化是否真正带来了系统数据。
    setState(() => _loading = true);
    final snapshot = await widget.onRequestPermissionAndRefresh();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InfoSheetFrame(
      title: '外部数据源',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EmptyCard(
            title: 'Health Connect 是可选数据源',
            subtitle: '没有授权或设备不支持时，状态中心仍然可以通过手动记录、饮食和锻炼数据正常使用。',
          ),
          const SizedBox(height: 12),
          _HealthSystemStatusCard(
            snapshot: _snapshot,
            loading: _loading,
            onRefresh: _refresh,
            onRequestPermission: _requestPermission,
            onOpenSettings: widget.onOpenSettings,
          ),
          const SizedBox(height: 12),
          _HealthSensorCard(snapshot: _snapshot.sensors),
        ],
      ),
    );
  }
}

class _HealthSystemStatusCard extends StatelessWidget {
  const _HealthSystemStatusCard({
    required this.snapshot,
    required this.loading,
    required this.onRefresh,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  final HealthSystemSnapshot snapshot;
  final bool loading;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRequestPermission;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final state = _HealthConnectionState.fromSnapshot(snapshot, loading);

    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: state.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  state.icon,
                  color: state.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '这是可选数据源，不影响状态中心使用。',
                      style: TextStyle(
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HealthStatusPill(
                label: 'Health Connect',
                value: state.badge,
              ),
              _HealthStatusPill(
                label: '传感器',
                value: snapshot.sensors.summary,
              ),
              _HealthStatusPill(
                label: '刷新',
                value: snapshot.lastUpdated == null
                    ? '未完成'
                    : _formatUpdated(snapshot.lastUpdated!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('刷新'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.opensSettings
                      ? onOpenSettings
                      : onRequestPermission,
                  icon: Icon(state.actionIcon, size: 18),
                  label: Text(state.actionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatUpdated(DateTime value) {
    final local = value.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.hour}:$minute';
  }
}

class _HealthConnectionState {
  const _HealthConnectionState({
    required this.title,
    required this.badge,
    required this.actionLabel,
    required this.icon,
    required this.actionIcon,
    required this.color,
    required this.opensSettings,
  });

  final String title;
  final String badge;
  final String actionLabel;
  final IconData icon;
  final IconData actionIcon;
  final Color color;
  final bool opensSettings;

  factory _HealthConnectionState.fromSnapshot(
    HealthSystemSnapshot snapshot,
    bool loading,
  ) {
    if (loading || snapshot.status == SystemHealthStatus.loading) {
      return const _HealthConnectionState(
        title: '正在读取系统健康数据',
        badge: '读取中',
        actionLabel: '刷新',
        icon: Icons.sync_rounded,
        actionIcon: Icons.refresh_rounded,
        color: AppColors.primary,
        opensSettings: false,
      );
    }
    if (snapshot.status == SystemHealthStatus.ok) {
      if (!snapshot.hasAnyData) {
        return const _HealthConnectionState(
          title: 'Health Connect 已连接，暂无数据',
          badge: '数据为空',
          actionLabel: '打开设置',
          icon: Icons.dataset_outlined,
          actionIcon: Icons.settings_rounded,
          color: AppColors.primary,
          opensSettings: true,
        );
      }
      return const _HealthConnectionState(
        title: '系统健康数据已连接',
        badge: '已连接',
        actionLabel: '打开设置',
        icon: Icons.verified_rounded,
        actionIcon: Icons.settings_rounded,
        color: AppColors.success,
        opensSettings: true,
      );
    }
    if (snapshot.status == SystemHealthStatus.permissionRequired) {
      return const _HealthConnectionState(
        title: 'Health Connect 未授权',
        badge: '未授权',
        actionLabel: '去授权',
        icon: Icons.lock_outline_rounded,
        actionIcon: Icons.lock_open_rounded,
        color: AppColors.primary,
        opensSettings: false,
      );
    }
    if (snapshot.status == SystemHealthStatus.updateRequired) {
      return const _HealthConnectionState(
        title: '需要更新 Health Connect',
        badge: '需更新',
        actionLabel: '去更新',
        icon: Icons.system_update_alt_rounded,
        actionIcon: Icons.open_in_new_rounded,
        color: AppColors.primary,
        opensSettings: true,
      );
    }
    if (snapshot.status == SystemHealthStatus.error) {
      return const _HealthConnectionState(
        title: '系统健康读取失败',
        badge: '读取失败',
        actionLabel: '重试',
        icon: Icons.error_outline_rounded,
        actionIcon: Icons.refresh_rounded,
        color: AppColors.financeRed,
        opensSettings: false,
      );
    }
    return const _HealthConnectionState(
      title: '需要安装 Health Connect',
      badge: '未安装',
      actionLabel: '去安装',
      icon: Icons.download_rounded,
      actionIcon: Icons.open_in_new_rounded,
      color: AppColors.primary,
      opensSettings: true,
    );
  }
}

class _HealthStatusPill extends StatelessWidget {
  const _HealthStatusPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
