import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/modules/health/health.dart';

void main() {
  test('status score rewards balanced daily state', () {
    final result = const HealthStatusCalculator().calculate(
      input: HealthStatusInput(
        sleep: HealthSleepFeeling.good,
        energy: HealthEnergyFeeling.strong,
        stress: HealthStressFeeling.low,
        body: HealthBodyFeeling.normal,
        mood: HealthMoodFeeling.calm,
        foodCalories: 1650,
        workoutGroups: 6,
      ),
    );

    expect(result.score, greaterThanOrEqualTo(85));
    expect(result.level, '状态很好');
    expect(result.primaryReason, '睡眠、精力和压力都比较稳定');
    expect(result.impacts.map((impact) => impact.title), contains('饮食'));
    expect(result.suggestions, contains('状态不错，可以安排中等强度任务或训练。'));
  });

  test('status score explains stress sleep and workout overload', () {
    final result = const HealthStatusCalculator().calculate(
      input: HealthStatusInput(
        sleep: HealthSleepFeeling.poor,
        energy: HealthEnergyFeeling.tired,
        stress: HealthStressFeeling.high,
        body: HealthBodyFeeling.neckPain,
        mood: HealthMoodFeeling.anxious,
        foodCalories: 900,
        workoutGroups: 18,
      ),
    );

    expect(result.score, lessThanOrEqualTo(54));
    expect(result.level, '负载偏高');
    expect(result.primaryReason, '睡眠感较差、压力偏高、身体有不适');
    expect(
      result.impacts.map((impact) => impact.title),
      containsAll(['锻炼', '情绪']),
    );
    expect(
      result.impacts.firstWhere((impact) => impact.title == '锻炼').label,
      '训练量偏高',
    );
    expect(
      result.impacts.firstWhere((impact) => impact.title == '情绪').label,
      '焦虑',
    );
    expect(result.suggestions, contains('今天压力偏高，优先处理高价值任务，减少低优先级事项。'));
    expect(result.suggestions, contains('情绪焦虑时，先安排 10 分钟放松或呼吸练习。'));
    expect(result.suggestions, contains('睡眠感较差且训练量偏高，今天更适合轻度训练或拉伸。'));
    expect(result.suggestions, contains('摄入偏低时不建议直接做高强度训练。'));
  });
}
