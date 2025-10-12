import '../database/based_helper.dart';
import '../models/securite_sante.dart';

class SecuriteSanteService {
  static const String table = 'securite_sante';
  final BasedHelper _db = BasedHelper();

  Future<List<SecuriteSante>> getAll({String? pays}) async {
    final list = await _db.getAll(table);
    final mapped = list.map((e) => SecuriteSante.fromMap(e)).toList();
    if (pays == null || pays.isEmpty) return mapped;
    return mapped.where((e) => e.pays.toLowerCase() == pays.toLowerCase()).toList();
  }

  Future<SecuriteSante?> getById(String id) async {
    final m = await _db.getById(table, id);
    return m == null ? null : SecuriteSante.fromMap(m);
  }

  Future<int> create(SecuriteSante item) async {
    return _db.insert(table, item.toMap());
  }

  Future<int> update(SecuriteSante item) async {
    return _db.update(table, item.toMap());
  }

  Future<int> delete(String id) async {
    return _db.delete(table, id);
  }
}
