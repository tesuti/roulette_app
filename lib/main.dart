import "package:flutter/material.dart";

void main() {
  runApp(const RouletteApp());
}

class RouletteApp extends StatelessWidget {
  const RouletteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Roulette",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const RouletteHomePage(),
    );
  }
}

class RouletteHomePage extends StatelessWidget {
  const RouletteHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Hello Roulette!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}