class SpinHistoryModel {
  SpinHistoryModel({
    this.id,
    required this.rouletteId,
    this.itemId,
    required this.resultLabel,
    DateTime? spunAt,
    this.notes = '',
  }) : spunAt = spunAt ?? DateTime.now();

  final int? id;
  final int rouletteId;
  final int? itemId;
  final String resultLabel;
  final DateTime spunAt;
  final String notes;

  SpinHistoryModel copyWith({
    int? id,
    int? rouletteId,
    int? itemId,
    String? resultLabel,
    DateTime? spunAt,
    String? notes,
  }) {
    return SpinHistoryModel(
      id: id ?? this.id,
      rouletteId: rouletteId ?? this.rouletteId,
      itemId: itemId ?? this.itemId,
      resultLabel: resultLabel ?? this.resultLabel,
      spunAt: spunAt ?? this.spunAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      'roulette_id': rouletteId,
      'item_id': itemId,
      'result_label': resultLabel,
      'spun_at': spunAt.millisecondsSinceEpoch,
      'notes': notes,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory SpinHistoryModel.fromMap(Map<String, dynamic> map) {
    return SpinHistoryModel(
      id: map['id'] as int?,
      rouletteId: map['roulette_id'] as int,
      itemId: map['item_id'] as int?,
      resultLabel: map['result_label'] as String? ?? '',
      spunAt: DateTime.fromMillisecondsSinceEpoch(map['spun_at'] as int),
      notes: map['notes'] as String? ?? '',
    );
  }
}
