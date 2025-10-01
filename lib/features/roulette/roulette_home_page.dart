import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/roulette_model.dart';
import '../../data/notifiers/roulette_notifier.dart';
import 'roulette_edit_page.dart';
import 'roulette_spin_page.dart';

class RouletteHomePage extends StatelessWidget {
  const RouletteHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<RouletteNotifier>();
    final roulettes = notifier.roulettes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ルーレット一覧'),
      ),
      body: Builder(
        builder: (context) {
          if (notifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (roulettes.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: roulettes.length,
            itemBuilder: (context, index) {
              final roulette = roulettes[index];
              return _RouletteListTile(roulette: roulette);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<RouletteModel?>(
            MaterialPageRoute(
              builder: (_) => const RouletteEditPage(),
            ),
          );
          if (result != null) {
            context.read<RouletteNotifier>().upsertRoulette(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RouletteListTile extends StatelessWidget {
  const _RouletteListTile({required this.roulette});

  final RouletteModel roulette;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          roulette.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '更新: ${_formatDate(roulette.updatedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () => _openSpinPage(context, roulette),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '回転',
              icon: const Icon(Icons.casino),
              onPressed: () => _openSpinPage(context, roulette),
            ),
            IconButton(
              tooltip: '編集',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.of(context).push<RouletteModel?>(
                  MaterialPageRoute(
                    builder: (_) => RouletteEditPage(rouletteId: roulette.id),
                  ),
                );
                if (result != null) {
                  context.read<RouletteNotifier>().upsertRoulette(result);
                }
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDelete(context, roulette);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('削除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, RouletteModel roulette) async {
    final notifier = context.read<RouletteNotifier>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: Text('「${roulette.title}」を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && roulette.id != null) {
      await notifier.deleteRoulette(roulette.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${roulette.title}」を削除しました。')),
        );
      }
    }
  }

  void _openSpinPage(BuildContext context, RouletteModel roulette) {
    if (roulette.id == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouletteSpinPage(rouletteId: roulette.id!),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'ルーレットがまだありません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '右下の＋ボタンから作成できます。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final date = '${local.year}/${twoDigits(local.month)}/${twoDigits(local.day)}';
  final time = '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  return '$date $time';
}
