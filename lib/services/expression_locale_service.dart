import '../database/based_helper.dart';
import '../models/expression_locale.dart';

class ExpressionLocaleService {
  static const String table = 'expression_locale';
  final BasedHelper _db = BasedHelper();

  Future<List<ExpressionLocale>> getAll({String? langue}) async {
    final list = await _db.getAll(table);
    final mapped = list.map((e) => ExpressionLocale.fromMap(e)).toList();
    if (langue == null || langue.isEmpty) return mapped;
    return mapped.where((e) => e.langue.toLowerCase() == langue.toLowerCase()).toList();
  }

  Future<ExpressionLocale?> getById(String id) async {
    final m = await _db.getById(table, id);
    return m == null ? null : ExpressionLocale.fromMap(m);
  }

  Future<int> create(ExpressionLocale item) async {
    return _db.insert(table, item.toMap());
  }

  Future<int> update(ExpressionLocale item) async {
    return _db.update(table, item.toMap());
  }

  Future<int> delete(String id) async {
    return _db.delete(table, id);
  }
}
