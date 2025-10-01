import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app/roulette_app.dart';
import 'data/repositories/roulette_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  final repository = await RouletteRepository.create();
  runApp(RouletteApp(repository: repository));
}
