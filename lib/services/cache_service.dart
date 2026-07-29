import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/supabase_config.dart';

class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();
  CacheService._();


  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.userBox);
    await Hive.openBox(AppConstants.coursesBox);
    await Hive.openBox(AppConstants.assignmentsBox);
    await Hive.openBox(AppConstants.noticesBox);
    await Hive.openBox(AppConstants.attendanceBox);
    await Hive.openBox(AppConstants.outboxBox);
  }


  Future<void> save(String boxName, String key, dynamic data) async {
    final box = Hive.box(boxName);
    final encoded = jsonEncode(data);
    await box.put(key, encoded);
    await box.put('${key}_timestamp', DateTime.now().toIso8601String());
  }


  T? get<T>(String boxName, String key, T Function(dynamic) fromJson) {
    try {
      final box = Hive.box(boxName);
      final raw = box.get(key);
      if (raw == null) return null;
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }


  List<Map<String, dynamic>>? getList(String boxName, String key) {
    try {
      final box = Hive.box(boxName);
      final raw = box.get(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }


  Future<void> saveList(String boxName, String key, List<Map<String, dynamic>> data) async {
    final box = Hive.box(boxName);
    await box.put(key, jsonEncode(data));
    await box.put('${key}_timestamp', DateTime.now().toIso8601String());
  }


  bool isStale(String boxName, String key, Duration ttl) {
    try {
      final box = Hive.box(boxName);
      final tsRaw = box.get('${key}_timestamp');
      if (tsRaw == null) return true;
      final ts = DateTime.parse(tsRaw);
      return DateTime.now().difference(ts) > ttl;
    } catch (_) {
      return true;
    }
  }


  Future<void> addToOutbox(String id, String type, Map<String, dynamic> payload) async {
    final box = Hive.box(AppConstants.outboxBox);
    await box.put(id, jsonEncode({'id': id, 'type': type, 'payload': payload, 'ts': DateTime.now().toIso8601String()}));
  }

  List<Map<String, dynamic>> getOutbox() {
    final box = Hive.box(AppConstants.outboxBox);
    return box.values.map((v) => jsonDecode(v) as Map<String, dynamic>).toList();
  }

  Future<void> removeFromOutbox(String id) async {
    await Hive.box(AppConstants.outboxBox).delete(id);
  }

  Future<void> clearBox(String boxName) async {
    await Hive.box(boxName).clear();
  }


  Future<void> clearUserData() async {
    await Hive.box(AppConstants.coursesBox).clear();
    await Hive.box(AppConstants.assignmentsBox).clear();
    await Hive.box(AppConstants.noticesBox).clear();
    await Hive.box(AppConstants.attendanceBox).clear();
    await Hive.box(AppConstants.outboxBox).clear();
  }
}