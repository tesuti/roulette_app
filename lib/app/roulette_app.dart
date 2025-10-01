import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/notifiers/roulette_notifier.dart';
import '../data/repositories/roulette_repository.dart';
import '../features/roulette/roulette_home_page.dart';

class RouletteApp extends StatelessWidget {
  const RouletteApp({super.key, required this.repository});

  final RouletteRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<RouletteRepository>.value(value: repository),
        ChangeNotifierProvider<RouletteNotifier>(
          create: (_) => RouletteNotifier(repository)..loadRoulettes(),
        ),
      ],
      child: MaterialApp(
        title: 'Roulette',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
          useMaterial3: true,
        ),
        home: const RouletteHomePage(),
      ),
    );
  }
}

