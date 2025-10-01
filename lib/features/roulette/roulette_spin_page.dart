import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/roulette_item_model.dart';
import '../../data/models/roulette_model.dart';
import '../../data/models/spin_history_model.dart';
import '../../data/notifiers/roulette_notifier.dart';
import '../../data/repositories/roulette_repository.dart';
import 'widgets/roulette_wheel.dart';

class RouletteSpinPage extends StatefulWidget {
  const RouletteSpinPage({super.key, required this.rouletteId});

  final int rouletteId;

  @override
  State<RouletteSpinPage> createState() => _RouletteSpinPageState();
}

class _RouletteSpinPageState extends State<RouletteSpinPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _angleAnimation;
  VoidCallback? _animationListener;

  RouletteModel? _roulette;
  List<RouletteItemModel> _items = <RouletteItemModel>[];
  List<_WheelSegment> _segments = <_WheelSegment>[];

  double _currentAngle = 0;
  bool _isLoading = true;
  bool _isSpinning = false;
  RouletteItemModel? _lastResult;
  RouletteItemModel? _pendingResult;
  int? _highlightedItemId;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _handleSpinCompleted();
        }
      });
    _loadData();
  }

  @override
  void dispose() {
    _angleAnimation?.removeListener(_animationListener ?? () {});
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repository = context.read<RouletteRepository>();
    final roulette = await repository.fetchRoulette(widget.rouletteId);
    final items = await repository.fetchItems(widget.rouletteId);

    setState(() {
      _roulette = roulette;
      _items = items;
      _segments = _buildSegments(items);
      _isLoading = false;
    });
  }

  List<_WheelSegment> _buildSegments(List<RouletteItemModel> items) {
    if (items.isEmpty) {
      return <_WheelSegment>[];
    }
    final weights = items
        .map((item) => item.weight <= 0 ? 1.0 : item.weight)
        .toList(growable: false);
    var total = weights.fold<double>(0, (sum, weight) => sum + weight);
    if (total == 0) {
      total = items.length.toDouble();
      for (var i = 0; i < weights.length; i++) {
        weights[i] = 1.0;
      }
    }

    final segments = <_WheelSegment>[];
    var startAngle = -math.pi / 2;
    for (var i = 0; i < items.length; i++) {
      final weight = weights[i];
      final sweep = (weight / total) * math.pi * 2;
      final center = startAngle + sweep / 2;
      segments.add(
        _WheelSegment(
          item: items[i],
          weight: weight,
          start: startAngle,
          sweep: sweep,
          center: center,
        ),
      );
      startAngle += sweep;
    }
    return segments;
  }

  void _startSpin() {
    if (_isSpinning || _segments.isEmpty) {
      return;
    }

    final selectedSegment = _chooseSegment();
    if (selectedSegment == null) {
      return;
    }

    final baseAngle = _currentAngle % (2 * math.pi);
    final alignAngle = (2 * math.pi - ((selectedSegment.center + baseAngle) % (2 * math.pi))) % (2 * math.pi);
    final additionalSpins = 2 * math.pi * (4 + _random.nextDouble() * 2);
    final targetAngle = _currentAngle + additionalSpins + alignAngle;

    _pendingResult = selectedSegment.item;
    _highlightedItemId = null;
    _lastResult = null;

    _angleAnimation?.removeListener(_animationListener ?? () {});
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _angleAnimation = Tween<double>(begin: _currentAngle, end: targetAngle).animate(curved);
    _animationListener = () {
      setState(() {
        _currentAngle = _angleAnimation!.value;
      });
    };
    _angleAnimation!.addListener(_animationListener!);

    setState(() {
      _isSpinning = true;
    });

    _controller
      ..reset()
      ..forward();
  }

  _WheelSegment? _chooseSegment() {
    if (_segments.isEmpty) {
      return null;
    }
    final totalWeight = _segments.fold<double>(0, (sum, segment) => sum + segment.weight);
    if (totalWeight == 0) {
      return _segments.first;
    }
    var threshold = _random.nextDouble() * totalWeight;
    for (final segment in _segments) {
      threshold -= segment.weight;
      if (threshold <= 0) {
        return segment;
      }
    }
    return _segments.last;
  }

  Future<void> _handleSpinCompleted() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isSpinning = false;
      _highlightedItemId = _pendingResult?.id;
      _lastResult = _pendingResult;
    });

    if (_pendingResult != null) {
      final repository = context.read<RouletteRepository>();
      await repository.createSpinHistory(
        SpinHistoryModel(
          rouletteId: widget.rouletteId,
          itemId: _pendingResult!.id,
          resultLabel: _pendingResult!.label,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _roulette?.title ?? 'ルーレット';
    return Scaffold(
      appBar: AppBar(
        title: Text('$title を回す'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Expanded(
                    child: Center(
                      child: RouletteWheel(
                        items: _items,
                        rotation: _currentAngle,
                        selectedItemId: _isSpinning ? null : _highlightedItemId,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _isSpinning
                        ? const _ResultText(key: ValueKey('spinning'), text: '回転中...', emphasized: false)
                        : _lastResult == null
                            ? const _ResultText(
                                key: ValueKey('ready'),
                                text: '「回す」を押してスタート',
                                emphasized: false,
                              )
                            : _ResultText(
                                key: ValueKey('result'),
                                text: _lastResult!.label,
                                emphasized: true,
                              ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _isSpinning || _segments.isEmpty ? null : _startSpin,
                    icon: const Icon(Icons.casino),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('回す'),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_segments.isEmpty)
                    Text(
                      'アイテムが設定されていません。編集から追加してください。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ResultText extends StatelessWidget {
  const _ResultText({super.key, required this.text, required this.emphasized});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          )
        : theme.textTheme.bodyLarge;
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: style ?? const TextStyle(fontSize: 20),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

class _WheelSegment {
  const _WheelSegment({
    required this.item,
    required this.weight,
    required this.start,
    required this.sweep,
    required this.center,
  });

  final RouletteItemModel item;
  final double weight;
  final double start;
  final double sweep;
  final double center;
}

