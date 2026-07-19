import 'dart:convert';

import 'package:flutter/services.dart';

class HealthManualRecordData {
  const HealthManualRecordData({
    required this.date,
    required this.bodyTag,
    required this.energyLevel,
    required this.fatigueLevel,
    required this.stressLevel,
    required this.painNote,
    required this.moodNote,
    required this.sleep,
    required this.energy,
    required this.stress,
    required this.body,
    required this.mood,
  });

  final DateTime date;
  final String bodyTag;
  final double energyLevel;
  final double fatigueLevel;
  final double stressLevel;
  final String painNote;
  final String moodNote;
  final String sleep;
  final String energy;
  final String stress;
  final String body;
  final String mood;

  String get dateKey => healthManualDateKey(date);

  Map<String, Object?> toJson() {
    return {
      'date': dateKey,
      'bodyTag': bodyTag,
      'energyLevel': energyLevel,
      'fatigueLevel': fatigueLevel,
      'stressLevel': stressLevel,
      'painNote': painNote,
      'moodNote': moodNote,
      'sleep': sleep,
      'energy': energy,
      'stress': stress,
      'body': body,
      'mood': mood,
    };
  }

  static HealthManualRecordData? fromJson(Map<String, Object?> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    if (date == null) {
      return null;
    }
    const stringFields = [
      'bodyTag',
      'painNote',
      'moodNote',
      'sleep',
      'energy',
      'stress',
      'body',
      'mood',
    ];
    if (stringFields.any(
      (key) => json[key] != null && json[key] is! String,
    )) {
      return null;
    }
    return HealthManualRecordData(
      date: DateTime(date.year, date.month, date.day),
      bodyTag: json['bodyTag'] as String? ?? '正常',
      energyLevel: _doubleValue(json['energyLevel'], 3),
      fatigueLevel: _doubleValue(json['fatigueLevel'], 2),
      stressLevel: _doubleValue(json['stressLevel'], 3),
      painNote: json['painNote'] as String? ?? '',
      moodNote: json['moodNote'] as String? ?? '平稳',
      sleep: json['sleep'] as String? ?? 'normal',
      energy: json['energy'] as String? ?? 'normal',
      stress: json['stress'] as String? ?? 'medium',
      body: json['body'] as String? ?? 'normal',
      mood: json['mood'] as String? ?? 'calm',
    );
  }
}

class HealthManualStore {
  const HealthManualStore();

  static const _channel = MethodChannel('pingsheng_life/health_manual');

  Future<List<HealthManualRecordData>> load() async {
    try {
      final raw =
          await _channel.invokeMethod<String>('loadHealthManualRecords');
      if (raw == null || raw.trim().isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => HealthManualRecordData.fromJson(
                item.cast<String, Object?>(),
              ))
          .whereType<HealthManualRecordData>()
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  Future<void> save(Iterable<HealthManualRecordData> records) async {
    final sorted = records.toList()
      ..sort((left, right) => right.date.compareTo(left.date));
    final recent = sorted.take(31).map((record) => record.toJson()).toList();
    try {
      await _channel.invokeMethod<void>('saveHealthManualRecords', {
        'recordsJson': jsonEncode(recent),
      });
    } on MissingPluginException {
      // 不支持原生通道的平台仍保留当前页面中的会话状态。
    } on PlatformException {
      // 原生存储暂不可用时不撤销用户刚完成的页面记录。
    }
  }
}

String healthManualDateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

double _doubleValue(Object? value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
