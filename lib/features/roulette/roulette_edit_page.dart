
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/roulette_item_model.dart';
import '../../data/models/roulette_model.dart';
import '../../data/notifiers/roulette_notifier.dart';
import '../../data/repositories/roulette_repository.dart';
import '../../utils/color_utils.dart';

class RouletteEditPage extends StatefulWidget {
  const RouletteEditPage({super.key, this.rouletteId});

  final int? rouletteId;

  @override
  State<RouletteEditPage> createState() => _RouletteEditPageState();
}

class _RouletteEditPageState extends State<RouletteEditPage> {
  final TextEditingController _titleController = TextEditingController();
  final List<RouletteItemModel> _items = <RouletteItemModel>[];
  final Set<int> _selectedIndices = <int>{};
  final Set<int> _removedItemIds = <int>{};

  bool _isLoading = true;
  bool _isSaving = false;
  RouletteModel? _roulette;

  static const List<Color> _colorPalette = <Color>[
    Color(0xFF6C63FF),
    Color(0xFF4ECDC4),
    Color(0xFFFF8C42),
    Color(0xFFFF477E),
    Color(0xFF00BBF9),
    Color(0xFF8338EC),
    Color(0xFF06D6A0),
    Color(0xFF118AB2),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _isSelectionMode => _selectedIndices.isNotEmpty;

  Future<void> _loadData() async {
    final repository = context.read<RouletteRepository>();
    RouletteModel? roulette;
    List<RouletteItemModel> items = <RouletteItemModel>[];

    if (widget.rouletteId != null) {
      roulette = await repository.fetchRoulette(widget.rouletteId!);
      if (roulette != null) {
        items = await repository.fetchItems(roulette.id!);
      }
    }

    roulette ??= RouletteModel(title: 'ルーレット');

    setState(() {
      _roulette = roulette;
      _titleController.text = roulette!.title;
      _items
        ..clear()
        ..addAll(items);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.rouletteId == null ? 'ルーレット作成' : 'ルーレット編集';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedIndices.length} 件選択' : title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '選択したアイテムを削除',
              onPressed: _deleteSelectedItems,
            )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _openNewItemSheet,
              icon: const Icon(Icons.add),
              label: const Text('アイテム追加'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'ルーレット名',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _items.isEmpty
                        ? const _EmptyItemsState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final isSelected = _selectedIndices.contains(index);
                              return _ItemTile(
                                item: item,
                                isSelected: isSelected,
                                selectionMode: _isSelectionMode,
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(index);
                                  } else {
                                    _openItemSheet(index: index);
                                  }
                                },
                                onLongPress: () => _toggleSelection(index),
                                onEdit: () => _openItemSheet(index: index),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _openNewItemSheet() async {
    await _openItemSheet();
  }

  Future<void> _openItemSheet({int? index}) async {
    final existing = index != null ? _items[index] : null;
    final result = await showModalBottomSheet<_ItemSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _ItemEditorSheet(
          initialLabel: existing?.label ?? '',
          initialWeight: existing?.weight ?? 1.0,
          initialColor: existing != null
              ? hexToColor(existing.colorHex)
              : _colorPalette[_items.length % _colorPalette.length],
        );
      },
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();
    setState(() {
      if (index != null) {
        final current = _items[index];
        _items[index] = current.copyWith(
          label: result.label,
          weight: result.weight,
          colorHex: colorToHex(result.color),
          updatedAt: now,
        );
      } else {
        _items.add(
          RouletteItemModel(
            rouletteId: _roulette?.id ?? 0,
            label: result.label,
            colorHex: colorToHex(result.color),
            weight: result.weight,
            sortOrder: _items.length,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      _reassignSortOrder();
    });
  }

  void _reassignSortOrder() {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      _items[i] = item.copyWith(sortOrder: i);
    }
  }

  void _deleteSelectedItems() {
    if (_selectedIndices.isEmpty) {
      return;
    }

    final sorted = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    final removedTitles = <String>[];

    setState(() {
      for (final index in sorted) {
        final removed = _items.removeAt(index);
        if (removed.id != null) {
          _removedItemIds.add(removed.id!);
        }
        removedTitles.add(removed.label);
      }
      _selectedIndices.clear();
      _reassignSortOrder();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${removedTitles.length} 件のアイテムを削除しました。')),
    );
  }

  Future<void> _saveChanges() async {
    if (_roulette == null || _isSaving) {
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルーレット名を入力してください。')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = context.read<RouletteRepository>();
      final notifier = context.read<RouletteNotifier>();
      final now = DateTime.now();
      RouletteModel current = _roulette!;

      if (current.id != null) {
        current = current.copyWith(
          title: title,
          updatedAt: now,
        );
        await repository.updateRoulette(current);
      } else {
        current = await repository.createRoulette(
          RouletteModel(
            title: title,
            description: current.description,
            colorHex: current.colorHex,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final rouletteId = current.id!;

      final List<RouletteItemModel> persistedItems = <RouletteItemModel>[];
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i].copyWith(
          rouletteId: rouletteId,
          sortOrder: i,
          updatedAt: now,
        );
        if (item.id == null) {
          final created = await repository.createItem(item);
          persistedItems.add(created);
        } else {
          await repository.updateItem(item);
          persistedItems.add(item);
        }
      }

      for (final id in _removedItemIds) {
        await repository.deleteItem(id);
      }

      notifier.upsertRoulette(current);

      if (mounted) {
        setState(() {
          _roulette = current;
          _items
            ..clear()
            ..addAll(persistedItems);
          _removedItemIds.clear();
          _selectedIndices.clear();
          _isSaving = false;
        });
        Navigator.of(context).pop(current);
      }
    } catch (error) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $error')),
      );
    }
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
  });

  final RouletteItemModel item;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(item.colorHex);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Text(
                item.label.isEmpty ? '?' : item.label.characters.first,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ウェイト: ${item.weight.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selectionMode)
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sentiment_satisfied_alt,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'アイテムがありません',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '右下の「アイテム追加」から追加できます。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemEditorSheet extends StatefulWidget {
  const _ItemEditorSheet({
    required this.initialLabel,
    required this.initialWeight,
    required this.initialColor,
  });

  final String initialLabel;
  final double initialWeight;
  final Color initialColor;

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  late TextEditingController _labelController;
  late double _weight;
  late Color _selectedColor;

  void _handleLabelChanged() => setState(() {});


  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
    _weight = widget.initialWeight.clamp(0.5, 5.0);
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'アイテムを編集',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'アイテム名',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Text(
            'ウェイト: ${_weight.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Slider(
            value: _weight,
            min: 0.5,
            max: 5.0,
            divisions: 9,
            label: _weight.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _weight = double.parse(value.toStringAsFixed(1));
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'カラー',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final color in _RouletteEditPageState._colorPalette)
                ChoiceChip(
                  label: const SizedBox(width: 24, height: 24),
                  selected: _selectedColor == color,
                  onSelected: (_) => setState(() => _selectedColor = color),
                  backgroundColor: color.withOpacity(0.3),
                  selectedColor: color,
                  labelPadding: EdgeInsets.zero,
                  side: BorderSide(color: color),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _labelController.text.trim().isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pop(
                          _ItemSheetResult(
                            label: _labelController.text.trim(),
                            weight: _weight,
                            color: _selectedColor,
                          ),
                        );
                      },
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemSheetResult {
  _ItemSheetResult({required this.label, required this.weight, required this.color});

  final String label;
  final double weight;
  final Color color;
}



