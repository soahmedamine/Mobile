import '../database/based_helper.dart';
import '../models/profil_culturel.dart';

class ProfilCulturelService {
  static const String table = 'profil_culturel';
  final BasedHelper _db = BasedHelper();

  Future<List<ProfilCulturel>> getAll({String? pays}) async {
    final list = await _db.getAll(table);
    final mapped = list.map((e) => ProfilCulturel.fromMap(e)).toList();
    if (pays == null || pays.isEmpty) return mapped;
    return mapped.where((e) => e.pays.toLowerCase() == pays.toLowerCase()).toList();
  }

  Future<ProfilCulturel?> getById(String id) async {
    final m = await _db.getById(table, id);
    return m == null ? null : ProfilCulturel.fromMap(m);
  }

  Future<int> create(ProfilCulturel item) async {
    return _db.insert(table, item.toMap());
  }

  Future<int> update(ProfilCulturel item) async {
    return _db.update(table, item.toMap());
  }

  Future<int> delete(String id) async {
    return _db.delete(table, id);
  }
}
