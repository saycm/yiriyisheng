// 中文注释：健康状态中心，负责把主观记录和生活数据计算成今日状态评分。

part of 'health.dart';

/// 睡眠感受：好/一般/差。
enum HealthSleepFeeling { good, normal, poor }

/// 精力感受：充沛/一般/疲惫。
enum HealthEnergyFeeling { strong, normal, tired }

/// 压力感受：低/中/高。
enum HealthStressFeeling { low, medium, high }

/// 身体感受：正常/颈痛/肠胃/头痛/其他。
enum HealthBodyFeeling { normal, neckPain, stomach, headache, other }

/// 心情感受：平静/愉快/焦虑/低落。
enum HealthMoodFeeling { calm, happy, anxious, low }

/// 提交给健康评分的输入：睡眠、精力、压力、身体和心情。
class HealthStatusInput {
  const HealthStatusInput({
    required this.sleep,
    required this.energy,
    required this.stress,
    required this.body,
    required this.mood,
    required this.foodCalories,
    required this.workoutGroups,
  });

  final HealthSleepFeeling sleep;
  final HealthEnergyFeeling energy;
  final HealthStressFeeling stress;
  final HealthBodyFeeling body;
  final HealthMoodFeeling mood;
  final int foodCalories;
  final int workoutGroups;
}

/// 某项状态对总分的影响说明。
class HealthStatusImpact {
  // 单个维度对总分的贡献，用于页面上的分项进度和解释文案。
  const HealthStatusImpact({
    required this.title,
    required this.label,
    required this.score,
    required this.maxScore,
    required this.color,
  });

  final String title;
  final String label;
  final int score;
  final int maxScore;
  final Color color;
}

/// 健康状态评分结果：总分、等级和建议。
class HealthStatusResult {
  const HealthStatusResult({
    required this.score,
    required this.level,
    required this.primaryReason,
    required this.impacts,
    required this.suggestions,
  });

  final int score;
  final String level;
  final String primaryReason;
  final List<HealthStatusImpact> impacts;
  final List<String> suggestions;
}

/// 健康状态计算器：把主观感受转换成 0-100 的状态分。
class HealthStatusCalculator {
  const HealthStatusCalculator();

  /// 汇总六项输入并生成完整状态结果；主观四项决定主分，饮食和训练只做负载修正。
  HealthStatusResult calculate({required HealthStatusInput input}) {
    // 评分模型保持简单透明：睡眠、精力、压力、身体为主，饮食和锻炼作为负载修正。
    final sleepScore = _sleepScore(input.sleep);
    final energyScore = _energyScore(input.energy);
    final stressScore = _stressScore(input.stress);
    final bodyScore = _bodyScore(input.body);
    final foodScore = _foodLoadScore(input.foodCalories);
    final workoutScore = _workoutLoadScore(input.workoutGroups);
    final loadScore = foodScore + workoutScore;
    final score =
        (sleepScore + energyScore + stressScore + bodyScore + loadScore)
            .clamp(0, 100);

    return HealthStatusResult(
      score: score,
      level: _level(score),
      primaryReason: _primaryReason(input),
      impacts: [
        HealthStatusImpact(
          title: '睡眠',
          label: _sleepLabel(input.sleep),
          score: sleepScore,
          maxScore: 25,
          color: AppColors.primary,
        ),
        HealthStatusImpact(
          title: '精力',
          label: _energyLabel(input.energy),
          score: energyScore,
          maxScore: 25,
          color: AppColors.success,
        ),
        HealthStatusImpact(
          title: '压力',
          label: _stressLabel(input.stress),
          score: stressScore,
          maxScore: 20,
          color: AppColors.sun,
        ),
        HealthStatusImpact(
          title: '身体',
          label: _bodyLabel(input.body),
          score: bodyScore,
          maxScore: 15,
          color: AppColors.lavender,
        ),
        HealthStatusImpact(
          title: '饮食',
          label: _foodLabel(input.foodCalories),
          score: foodScore,
          maxScore: 7,
          color: AppColors.accent,
        ),
        HealthStatusImpact(
          title: '锻炼',
          label: _workoutLabel(input.workoutGroups),
          score: workoutScore,
          maxScore: 8,
          color: AppColors.sky,
        ),
        HealthStatusImpact(
          title: '情绪',
          label: _moodLabel(input.mood),
          score: 0,
          maxScore: 0,
          color: AppColors.muted,
        ),
      ],
      suggestions: _suggestions(input, score),
    );
  }

  /// 睡眠感受换算为 25 分制：好 25 分、一般 18 分、差 7 分。
  int _sleepScore(HealthSleepFeeling value) {
    switch (value) {
      case HealthSleepFeeling.good:
        return 25;
      case HealthSleepFeeling.normal:
        return 18;
      case HealthSleepFeeling.poor:
        return 7;
    }
  }

  /// 精力感受换算为 25 分制：充沛 25 分、一般 18 分、疲惫 7 分。
  int _energyScore(HealthEnergyFeeling value) {
    switch (value) {
      case HealthEnergyFeeling.strong:
        return 25;
      case HealthEnergyFeeling.normal:
        return 18;
      case HealthEnergyFeeling.tired:
        return 7;
    }
  }

  /// 压力感受换算为 20 分制：低 20 分、中 12 分、高 4 分。
  int _stressScore(HealthStressFeeling value) {
    switch (value) {
      case HealthStressFeeling.low:
        return 20;
      case HealthStressFeeling.medium:
        return 12;
      case HealthStressFeeling.high:
        return 4;
    }
  }

  /// 身体感受换算为 15 分制：正常 15 分，出现任何不适统一记 6 分。
  int _bodyScore(HealthBodyFeeling value) {
    switch (value) {
      case HealthBodyFeeling.normal:
        return 15;
      case HealthBodyFeeling.neckPain:
      case HealthBodyFeeling.stomach:
      case HealthBodyFeeling.headache:
      case HealthBodyFeeling.other:
        return 6;
    }
  }

  /// 根据当日热量判断饮食负载，过少或过多都会降低该项得分。
  int _foodLoadScore(int calories) {
    if (calories < 1200) {
      return 0;
    }
    if (calories > 2600) {
      return 4;
    }
    return 7;
  }

  /// 根据当日训练组数判断训练负载，超过 10 组开始扣分，超过 14 组归零。
  int _workoutLoadScore(int workoutGroups) {
    if (workoutGroups > 14) {
      return 0;
    }
    if (workoutGroups > 10) {
      return 4;
    }
    return 8;
  }

  /// 把 0-100 总分映射成页面展示的状态等级。
  String _level(int score) {
    if (score >= 85) {
      return '状态很好';
    }
    if (score >= 70) {
      return '状态平稳';
    }
    if (score >= 55) {
      return '稍累';
    }
    return '负载偏高';
  }

  /// 找出最需要解释的主要原因，供状态卡片作为一句话摘要展示。
  String _primaryReason(HealthStatusInput input) {
    if (input.sleep != HealthSleepFeeling.poor &&
        input.energy != HealthEnergyFeeling.tired &&
        input.stress != HealthStressFeeling.high) {
      return '睡眠、精力和压力都比较稳定';
    }

    final reasons = <String>[];
    if (input.sleep == HealthSleepFeeling.poor) {
      reasons.add('睡眠感较差');
    }
    if (input.stress == HealthStressFeeling.high) {
      reasons.add('压力偏高');
    }
    if (input.body != HealthBodyFeeling.normal) {
      reasons.add('身体有不适');
    }
    if (reasons.isEmpty && input.energy == HealthEnergyFeeling.tired) {
      reasons.add('精力偏低');
    }
    return reasons.join('、');
  }

  /// 根据总分、压力、情绪、睡眠、饮食和训练量生成可执行建议。
  List<String> _suggestions(HealthStatusInput input, int score) {
    // 建议按最影响当天安排的因素追加，页面只展示短句，避免医疗化判断。
    final suggestions = <String>[];
    if (score >= 85) {
      suggestions.add('状态不错，可以安排中等强度任务或训练。');
    }
    if (input.stress == HealthStressFeeling.high) {
      suggestions.add('今天压力偏高，优先处理高价值任务，减少低优先级事项。');
    }
    if (input.mood == HealthMoodFeeling.anxious) {
      suggestions.add('情绪焦虑时，先安排 10 分钟放松或呼吸练习。');
    }
    if (input.mood == HealthMoodFeeling.low) {
      suggestions.add('情绪低落时，先完成一件轻量事项，减少自我消耗。');
    }
    if (input.sleep == HealthSleepFeeling.poor && input.workoutGroups > 14) {
      suggestions.add('睡眠感较差且训练量偏高，今天更适合轻度训练或拉伸。');
    }
    if (input.foodCalories < 1200) {
      suggestions.add('摄入偏低时不建议直接做高强度训练。');
    }
    if (suggestions.isEmpty) {
      suggestions.add('保持当前节奏，留意睡眠、饮食和训练负载的变化。');
    }
    return suggestions;
  }
}

// 把饮食热量转换成状态页展示文案。
String _foodLabel(int calories) {
  if (calories < 1200) {
    return '摄入偏低';
  }
  if (calories > 2600) {
    return '摄入偏高';
  }
  return '$calories 千卡';
}

// 把训练组数转换成状态页展示文案。
String _workoutLabel(int workoutGroups) {
  if (workoutGroups > 14) {
    return '训练量偏高';
  }
  if (workoutGroups > 10) {
    return '训练量略高';
  }
  if (workoutGroups == 0) {
    return '未训练';
  }
  return '$workoutGroups 组';
}

// 把睡眠枚举转换成中文标签。
String _sleepLabel(HealthSleepFeeling value) {
  switch (value) {
    case HealthSleepFeeling.good:
      return '睡眠较好';
    case HealthSleepFeeling.normal:
      return '睡眠一般';
    case HealthSleepFeeling.poor:
      return '睡眠感较差';
  }
}

// 把精力枚举转换成中文标签。
String _energyLabel(HealthEnergyFeeling value) {
  switch (value) {
    case HealthEnergyFeeling.strong:
      return '精力充足';
    case HealthEnergyFeeling.normal:
      return '精力平稳';
    case HealthEnergyFeeling.tired:
      return '精力偏低';
  }
}

// 把压力枚举转换成中文标签。
String _stressLabel(HealthStressFeeling value) {
  switch (value) {
    case HealthStressFeeling.low:
      return '压力较低';
    case HealthStressFeeling.medium:
      return '压力中等';
    case HealthStressFeeling.high:
      return '压力偏高';
  }
}

// 把身体感受枚举转换成中文标签。
String _bodyLabel(HealthBodyFeeling value) {
  switch (value) {
    case HealthBodyFeeling.normal:
      return '身体正常';
    case HealthBodyFeeling.neckPain:
      return '肩颈不适';
    case HealthBodyFeeling.stomach:
      return '胃部不适';
    case HealthBodyFeeling.headache:
      return '头痛';
    case HealthBodyFeeling.other:
      return '身体不适';
  }
}

// 把心情枚举转换成中文标签。
String _moodLabel(HealthMoodFeeling value) {
  switch (value) {
    case HealthMoodFeeling.calm:
      return '情绪平稳';
    case HealthMoodFeeling.happy:
      return '心情不错';
    case HealthMoodFeeling.anxious:
      return '焦虑';
    case HealthMoodFeeling.low:
      return '情绪偏低';
  }
}
