part of '../../main.dart';

class WorkoutPlan {
  WorkoutPlan({
    String? id,
    required this.name,
    required this.target,
    required List<String> bodyParts,
    required List<String> actionNames,
    required this.estimatedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _newLocalId(),
        bodyParts = List.of(bodyParts),
        actionNames = List.of(actionNames),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String target;
  final List<String> bodyParts;
  final List<String> actionNames;
  final int estimatedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int totalGroupsFrom(List<WorkoutAction> actions) {
    var total = 0;
    for (final action in actions) {
      if (actionNames.contains(action.name)) {
        total += action.groups;
      }
    }
    return total;
  }

  WorkoutPlan copyWith({
    String? name,
    String? target,
    List<String>? bodyParts,
    List<String>? actionNames,
    int? estimatedMinutes,
    DateTime? updatedAt,
  }) {
    return WorkoutPlan(
      id: id,
      name: name ?? this.name,
      target: target ?? this.target,
      bodyParts: bodyParts ?? this.bodyParts,
      actionNames: actionNames ?? this.actionNames,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'target': target,
      'bodyParts': List.of(bodyParts),
      'actionNames': List.of(actionNames),
      'estimatedMinutes': estimatedMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static WorkoutPlan fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final target = json['target'];
    final estimatedMinutes = json['estimatedMinutes'];
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    return WorkoutPlan(
      id: json['id'] is String ? json['id'] as String : null,
      name: name is String && name.isNotEmpty ? name : '未命名计划',
      target: target is String && target.isNotEmpty ? target : '今日训练',
      bodyParts: _stringListFromJson(json['bodyParts']),
      actionNames: _stringListFromJson(json['actionNames']),
      estimatedMinutes: estimatedMinutes is num
          ? estimatedMinutes.toInt()
          : int.tryParse(estimatedMinutes?.toString() ?? '') ?? 20,
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? createdAt,
    );
  }
}

class ActiveWorkoutSession {
  ActiveWorkoutSession({
    String? id,
    required this.planId,
    required this.planName,
    required this.startedAt,
    required Map<String, int> actionProgress,
    this.feedback = '刚好',
  })  : id = id ?? _newLocalId(),
        actionProgress = Map.of(actionProgress);

  final String id;
  final String planId;
  final String planName;
  final DateTime startedAt;
  final Map<String, int> actionProgress;
  final String feedback;

  int groupsFor(String actionName) {
    return actionProgress[actionName] ?? 0;
  }

  ActiveWorkoutSession copyWith({
    Map<String, int>? actionProgress,
    String? feedback,
  }) {
    return ActiveWorkoutSession(
      id: id,
      planId: planId,
      planName: planName,
      startedAt: startedAt,
      actionProgress: actionProgress ?? this.actionProgress,
      feedback: feedback ?? this.feedback,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planName': planName,
      'startedAt': startedAt.toIso8601String(),
      'actionProgress': Map.of(actionProgress),
      'feedback': feedback,
    };
  }

  static ActiveWorkoutSession fromJson(Map<String, Object?> json) {
    final planId = json['planId'];
    final planName = json['planName'];
    final feedback = json['feedback'];
    return ActiveWorkoutSession(
      id: json['id'] is String ? json['id'] as String : null,
      planId: planId is String ? planId : '',
      planName: planName is String ? planName : '未命名计划',
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      actionProgress: _intMapFromJson(json['actionProgress']),
      feedback: feedback is String ? feedback : '刚好',
    );
  }
}

class WorkoutActionResult {
  const WorkoutActionResult({
    required this.actionName,
    required this.bodyPart,
    required this.targetGroups,
    required this.finishedGroups,
    required this.reps,
    this.weight,
  });

  final String actionName;
  final String bodyPart;
  final int targetGroups;
  final int finishedGroups;
  final String reps;
  final String? weight;

  Map<String, Object?> toJson() {
    return {
      'actionName': actionName,
      'bodyPart': bodyPart,
      'targetGroups': targetGroups,
      'finishedGroups': finishedGroups,
      'reps': reps,
      'weight': weight,
    };
  }

  static WorkoutActionResult fromJson(Map<String, Object?> json) {
    final actionName = json['actionName'];
    final bodyPart = json['bodyPart'];
    final targetGroups = json['targetGroups'];
    final finishedGroups = json['finishedGroups'];
    final reps = json['reps'];
    final weight = json['weight'];
    return WorkoutActionResult(
      actionName: actionName is String ? actionName : '',
      bodyPart: bodyPart is String ? bodyPart : '',
      targetGroups: targetGroups is num
          ? targetGroups.toInt()
          : int.tryParse(targetGroups?.toString() ?? '') ?? 0,
      finishedGroups: finishedGroups is num
          ? finishedGroups.toInt()
          : int.tryParse(finishedGroups?.toString() ?? '') ?? 0,
      reps: reps is String ? reps : '',
      weight: weight is String ? weight : null,
    );
  }
}

class WorkoutHistoryEntry {
  WorkoutHistoryEntry({
    String? id,
    required this.planId,
    required this.planName,
    required this.startedAt,
    required this.finishedAt,
    required this.durationMinutes,
    required this.totalGroups,
    required this.estimatedCalories,
    required List<WorkoutActionResult> actionResults,
    this.feedback = '刚好',
  })  : id = id ?? _newLocalId(),
        actionResults = List.of(actionResults);

  final String id;
  final String planId;
  final String planName;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int durationMinutes;
  final int totalGroups;
  final int estimatedCalories;
  final List<WorkoutActionResult> actionResults;
  final String feedback;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planName': planName,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'totalGroups': totalGroups,
      'estimatedCalories': estimatedCalories,
      'actionResults': actionResults.map((result) => result.toJson()).toList(),
      'feedback': feedback,
    };
  }

  static WorkoutHistoryEntry fromJson(Map<String, Object?> json) {
    final planId = json['planId'];
    final planName = json['planName'];
    final durationMinutes = json['durationMinutes'];
    final totalGroups = json['totalGroups'];
    final estimatedCalories = json['estimatedCalories'];
    final feedback = json['feedback'];
    final startedAt = DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
        DateTime.now();
    return WorkoutHistoryEntry(
      id: json['id'] is String ? json['id'] as String : null,
      planId: planId is String ? planId : '',
      planName: planName is String ? planName : '未命名计划',
      startedAt: startedAt,
      finishedAt:
          DateTime.tryParse(json['finishedAt']?.toString() ?? '') ?? startedAt,
      durationMinutes: durationMinutes is num
          ? durationMinutes.toInt()
          : int.tryParse(durationMinutes?.toString() ?? '') ?? 0,
      totalGroups: totalGroups is num
          ? totalGroups.toInt()
          : int.tryParse(totalGroups?.toString() ?? '') ?? 0,
      estimatedCalories: estimatedCalories is num
          ? estimatedCalories.toInt()
          : int.tryParse(estimatedCalories?.toString() ?? '') ?? 0,
      actionResults: _actionResultsFromJson(json['actionResults']),
      feedback: feedback is String ? feedback : '刚好',
    );
  }
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) {
    return [];
  }
  return value.whereType<String>().toList();
}

Map<String, int> _intMapFromJson(Object? value) {
  if (value is! Map) {
    return {};
  }
  final result = <String, int>{};
  for (final entry in value.entries) {
    final mapValue = entry.value;
    final parsedValue = mapValue is num
        ? mapValue.toInt()
        : mapValue is String
            ? num.tryParse(mapValue.trim())?.toInt()
            : null;
    if (entry.key is String && parsedValue != null) {
      result[entry.key as String] = parsedValue;
    }
  }
  return result;
}

List<WorkoutActionResult> _actionResultsFromJson(Object? value) {
  if (value is! List) {
    return [];
  }
  final results = <WorkoutActionResult>[];
  for (final item in value) {
    if (item is Map) {
      final json = <String, Object?>{};
      for (final entry in item.entries) {
        if (entry.key is String) {
          json[entry.key as String] = entry.value;
        }
      }
      results.add(WorkoutActionResult.fromJson(json));
    }
  }
  return results;
}

List<WorkoutPlan> _createDefaultWorkoutPlans() {
  final now = DateTime.now();
  return [
    WorkoutPlan(
      id: 'plan-chest-back',
      name: '胸背强化',
      target: '胸背力量和体态稳定',
      bodyParts: const ['胸背'],
      actionNames: const [
        '蝴蝶机夹胸',
        '宽握高位下拉',
        '器械推胸',
        '坐姿绳索划船',
        '上斜哑铃卧推',
      ],
      estimatedMinutes: 38,
      createdAt: now,
      updatedAt: now,
    ),
    WorkoutPlan(
      id: 'plan-leg-stability',
      name: '腿部稳定',
      target: '下肢力量和髋膝稳定',
      bodyParts: const ['腿臀'],
      actionNames: const [
        '杠铃深蹲',
        '腿举',
        '罗马尼亚硬拉',
        '保加利亚分腿蹲',
      ],
      estimatedMinutes: 34,
      createdAt: now,
      updatedAt: now,
    ),
    WorkoutPlan(
      id: 'plan-core-recovery',
      name: '核心恢复',
      target: '核心控制和轻恢复',
      bodyParts: const ['核心', '拉伸'],
      actionNames: const [
        '平板支撑',
        '死虫',
        '猫牛式伸展',
        '儿童式放松',
      ],
      estimatedMinutes: 24,
      createdAt: now,
      updatedAt: now,
    ),
    WorkoutPlan(
      id: 'plan-quick-ten',
      name: '快练 10 分钟',
      target: '碎片时间快速激活',
      bodyParts: const ['核心', '有氧'],
      actionNames: const [
        '登山跑',
        '俄罗斯转体',
        '波比跳',
      ],
      estimatedMinutes: 10,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
