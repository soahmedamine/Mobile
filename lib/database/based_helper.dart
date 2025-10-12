import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BasedHelper {
  static final BasedHelper _instance = BasedHelper._internal();
  factory BasedHelper() => _instance;
  BasedHelper._internal();

  late SharedPreferences _prefs;
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    _prefs = await SharedPreferences.getInstance();
    _inited = true;
  }

  Future<String> _nextId() async {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    await init();
    final id = await _nextId();
    data['id'] = id;
    final key = '$table-$id';
    await _prefs.setString(key, jsonEncode(data));
    return 1;
  }

  Future<List<Map<String, dynamic>>> getAll(String table) async {
    await init();
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith('$table-'))
        .toList();
    final list = <Map<String, dynamic>>[];
    for (final k in keys) {
      final s = _prefs.getString(k);
      if (s != null) {
        list.add(Map<String, dynamic>.from(jsonDecode(s)));
      }
    }
    return list;
  }

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    await init();
    final s = _prefs.getString('$table-$id');
    if (s == null) return null;
    return Map<String, dynamic>.from(jsonDecode(s));
  }

  Future<int> update(String table, Map<String, dynamic> data) async {
    await init();
    final id = data['id'];
    if (id == null) return 0;
    final key = '$table-$id';
    final exists = _prefs.containsKey(key);
    if (!exists) return 0;
    await _prefs.setString(key, jsonEncode(data));
    return 1;
  }

  Future<int> delete(String table, String id) async {
    await init();
    final ok = await _prefs.remove('$table-$id');
    return ok ? 1 : 0;
  }
}
