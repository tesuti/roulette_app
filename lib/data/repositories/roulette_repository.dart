import 'package:sqflite/sqflite.dart';

import '../datasources/local/roulette_database.dart';
import '../models/roulette_item_model.dart';
import '../models/roulette_model.dart';
import '../models/spin_history_model.dart';

class RouletteRepository {
  RouletteRepository(this._database);

  final Database _database;

  static Future<RouletteRepository> create() async {
    final database = await RouletteDatabase.instance.database;
    return RouletteRepository(database);
  }

  Future<RouletteModel> createRoulette(RouletteModel roulette) async {
    final id = await _database.insert(
      RouletteDatabase.rouletteTable,
      roulette.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return roulette.copyWith(id: id);
  }

  Future<RouletteModel?> fetchRoulette(int id) async {
    final rows = await _database.query(
      RouletteDatabase.rouletteTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return RouletteModel.fromMap(rows.first);
  }

  Future<List<RouletteModel>> fetchAllRoulettes() async {
    final rows = await _database.query(
      RouletteDatabase.rouletteTable,
      orderBy: 'created_at DESC',
    );
    return rows.map(RouletteModel.fromMap).toList();
  }

  Future<int> updateRoulette(RouletteModel roulette) async {
    final updated = roulette.copyWith(updatedAt: DateTime.now());
    return _database.update(
      RouletteDatabase.rouletteTable,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
  }

  Future<int> deleteRoulette(int id) {
    return _database.delete(
      RouletteDatabase.rouletteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<RouletteItemModel> createItem(RouletteItemModel item) async {
    final id = await _database.insert(
      RouletteDatabase.itemTable,
      item.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return item.copyWith(id: id);
  }

  Future<List<RouletteItemModel>> fetchItems(int rouletteId) async {
    final rows = await _database.query(
      RouletteDatabase.itemTable,
      where: 'roulette_id = ?',
      whereArgs: [rouletteId],
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(RouletteItemModel.fromMap).toList();
  }

  Future<int> updateItem(RouletteItemModel item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    return _database.update(
      RouletteDatabase.itemTable,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
  }

  Future<int> deleteItem(int itemId) {
    return _database.delete(
      RouletteDatabase.itemTable,
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<SpinHistoryModel> createSpinHistory(SpinHistoryModel history) async {
    final id = await _database.insert(
      RouletteDatabase.spinHistoryTable,
      history.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return history.copyWith(id: id);
  }

  Future<List<SpinHistoryModel>> fetchSpinHistory(
    int rouletteId, {
    int limit = 50,
  }) async {
    final rows = await _database.query(
      RouletteDatabase.spinHistoryTable,
      where: 'roulette_id = ?',
      whereArgs: [rouletteId],
      orderBy: 'spun_at DESC',
      limit: limit,
    );
    return rows.map(SpinHistoryModel.fromMap).toList();
  }
}
