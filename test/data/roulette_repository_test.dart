import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:roulette_app/data/datasources/local/roulette_database.dart';
import 'package:roulette_app/data/models/roulette_item_model.dart';
import 'package:roulette_app/data/models/roulette_model.dart';
import 'package:roulette_app/data/repositories/roulette_repository.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late RouletteRepository repository;
  late RouletteModel roulette;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await RouletteDatabase.createSchema(db);
        },
      ),
    );

    repository = RouletteRepository(database);
    roulette = await repository.createRoulette(
      RouletteModel(title: 'Sample Roulette'),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('persists roulette items when created', () async {
    final created = await repository.createItem(
      RouletteItemModel(
        rouletteId: roulette.id!,
        label: 'Draft Coffee',
        colorHex: '#FFAA00',
        weight: 1.0,
        sortOrder: 0,
      ),
    );

    expect(created.id, isNotNull);

    final items = await repository.fetchItems(roulette.id!);
    expect(items, hasLength(1));
    expect(items.first.label, 'Draft Coffee');
    expect(items.first.rouletteId, roulette.id);
  });

  test('removes roulette items from storage', () async {
    final item = await repository.createItem(
      RouletteItemModel(
        rouletteId: roulette.id!,
        label: 'Take a break',
      ),
    );

    final deletedCount = await repository.deleteItem(item.id!);
    expect(deletedCount, 1);

    final items = await repository.fetchItems(roulette.id!);
    expect(items, isEmpty);
  });
}
