import 'package:flutter/material.dart';

import 'app/roulette_app.dart';
import 'data/repositories/roulette_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await RouletteRepository.create();
  runApp(RouletteApp(repository: repository));
}
