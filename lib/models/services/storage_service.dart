import 'dart
';

import 'package
/shared_preferences.dart';

import '../models/models.dart';

class StorageService {

static late SharedPreferences _prefs;

static Future<void> init() async {

_prefs = await SharedPreferences.getInstance();

}

// ذخیره دروس

static Future<void> saveSubjects(List<Subject> subjects) async {

List<String> jsonList =

subjects.map((s) => jsonEncode(s.toJson())).toList();

await _prefs.setStringList('subjects', jsonList);

}

static List<Subject> loadSubjects() {

List<String>? jsonList = _prefs.getStringList('subjects');

if (jsonList == null) return [];

return jsonList.map((s) => Subject.fromJson(jsonDecode(s))).toList();

}

// ذخیره تاریخچه

static Future<void> saveHistory(List<HistoryItem> history) async {

List<String> jsonList =

history.map((h) => jsonEncode(h.toJson())).toList();

await _prefs.setStringList('history', jsonList);

}

static List<HistoryItem> loadHistory() {

List<String>? jsonList = _prefs.getStringList('history');

if (jsonList == null) return [];

return jsonList.map((h) => HistoryItem.fromJson(jsonDecode(h))).toList();

}

// تنظیمات

static Future<void> setApiKey(String key) async {

await _prefs.setString('api_key', key);

}

static String? getApiKey() {

return _prefs.getString('api_key');

}

}

