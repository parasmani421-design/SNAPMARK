import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CampusInfoStore {
  CampusInfoStore._();

  static const _key = 'snapmark.campus.info.v1';
  static const labels = <String, String>{
    'stationery': 'Stationery shop',
    'medical': 'Medical / first-aid room',
    'erp': 'ERP office',
  };
  static const _defaults = <String, String>{
    'stationery': 'A Block, 2nd floor, next to Room 213',
    'medical': 'C Block',
    'erp': 'A Block, 3rd floor, Room 305',
  };
  static final Map<String, String> _locations = {..._defaults};

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final key = entry.key.toString();
          final value = entry.value.toString().trim();
          if (labels.containsKey(key) && value.isNotEmpty) {
            _locations[key] = value;
          }
        }
      }
    } catch (_) {
      // Keep the bundled campus information if saved data is unreadable.
    }
  }

  static String location(String key) => _locations[key] ?? _defaults[key] ?? '';

  static Future<void> saveLocation(String key, String location) async {
    final value = location.trim();
    if (!labels.containsKey(key) || value.isEmpty) return;
    _locations[key] = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(_locations));
  }
}
