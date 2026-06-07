import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../models/app_data.dart';

class LocalDataService {
  static const _storageKey = 'latente_local_data_v1';

  Future<AppData> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawData = preferences.getString(_storageKey);

    if (rawData == null || rawData.trim().isEmpty) {
      final sampleData = SampleData.create();
      await save(sampleData);
      return sampleData;
    }

    try {
      return SampleData.ensureReferenceData(decode(rawData));
    } catch (_) {
      final sampleData = SampleData.create();
      await save(sampleData);
      return sampleData;
    }
  }

  Future<void> save(AppData data) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, encode(data));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  String encode(AppData data) {
    return const JsonEncoder.withIndent('  ').convert(data.toJson());
  }

  AppData decode(String rawJson) {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return AppData.fromJson(decoded);
  }
}
