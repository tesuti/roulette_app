import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/roulette_model.dart';
import '../repositories/roulette_repository.dart';

class RouletteNotifier extends ChangeNotifier {
  RouletteNotifier(this._repository);

  final RouletteRepository _repository;
  final List<RouletteModel> _roulettes = <RouletteModel>[];
  bool _isLoading = false;

  UnmodifiableListView<RouletteModel> get roulettes => UnmodifiableListView(_roulettes);
  bool get isLoading => _isLoading;
  RouletteRepository get repository => _repository;

  Future<void> loadRoulettes() async {
    _setLoading(true);
    final result = await _repository.fetchAllRoulettes();
    _roulettes
      ..clear()
      ..addAll(result);
    _setLoading(false);
  }

  Future<RouletteModel> createRoulette({String title = 'ÉãÅ[ÉåÉbÉg'}) async {
    final now = DateTime.now();
    final roulette = RouletteModel(
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    final created = await _repository.createRoulette(roulette);
    upsertRoulette(created);
    return created;
  }

  Future<void> reloadRoulette(int id) async {
    final roulette = await _repository.fetchRoulette(id);
    if (roulette != null) {
      upsertRoulette(roulette);
    }
  }

  Future<void> deleteRoulette(int id) async {
    final deleted = await _repository.deleteRoulette(id);
    if (deleted > 0) {
      _roulettes.removeWhere((roulette) => roulette.id == id);
      notifyListeners();
    }
  }

  void upsertRoulette(RouletteModel roulette) {
    final index = _roulettes.indexWhere((element) => element.id == roulette.id);
    if (index >= 0) {
      _roulettes[index] = roulette;
    } else {
      _roulettes.insert(0, roulette);
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
