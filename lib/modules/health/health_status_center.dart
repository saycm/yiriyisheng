part of 'health.dart';

enum HealthSleepFeeling { good, normal, poor }

enum HealthEnergyFeeling { strong, normal, tired }

enum HealthStressFeeling { low, medium, high }

enum HealthBodyFeeling { normal, neckPain, stomach, headache, other }

enum HealthMoodFeeling { calm, happy, anxious, low }

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

class HealthStatusImpact {
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

class HealthStatusCalculator {
  const HealthStatusCalculator();

  HealthStatusResult calculate({required HealthStatusInput input}) {
    final sleepScore = _sleepScore(input.sleep);
    final energyScore = _energyScore(input.energy);
    final stressScore = _stressScore(input.stress);
    final bodyScore = _bodyScore(input.body);
    final loadScore = _loadScore(
      foodCalories: input.foodCalories,
      workoutGroups: input.workoutGroups,
    );
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
          label: '${input.foodCalories} 千卡',
          score: loadScore,
          maxScore: 15,
          color: AppColors.accent,
        ),
      ],
      suggestions: _suggestions(input, score),
    );
  }

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

  int _loadScore({
    required int foodCalories,
    required int workoutGroups,
  }) {
    var score = 15;
    if (foodCalories < 1200) {
      score -= 7;
    } else if (foodCalories > 2600) {
      score -= 3;
    }
    if (workoutGroups > 14) {
      score -= 8;
    } else if (workoutGroups > 10) {
      score -= 4;
    }
    return score.clamp(0, 15);
  }

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

  List<String> _suggestions(HealthStatusInput input, int score) {
    final suggestions = <String>[];
    if (score >= 85) {
      suggestions.add('状态不错，可以安排中等强度任务或训练。');
    }
    if (input.stress == HealthStressFeeling.high) {
      suggestions.add('今天压力偏高，优先处理高价值任务，减少低优先级事项。');
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

String _bodyLabel(HealthBodyFeeling value) {
  switch (value) {
    case HealthBodyFeeling.normal:
      return '身体正常';
    case HealthBodyFeeling.neckPain:
      return '颈肩不适';
    case HealthBodyFeeling.stomach:
      return '胃部不适';
    case HealthBodyFeeling.headache:
      return '头痛';
    case HealthBodyFeeling.other:
      return '身体不适';
  }
}

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
