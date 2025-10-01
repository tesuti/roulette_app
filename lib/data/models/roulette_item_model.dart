class RouletteItemModel {
  RouletteItemModel({
    this.id,
    required this.rouletteId,
    required this.label,
    this.colorHex = '#FFFFFF',
    this.weight = 1.0,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final int? id;
  final int rouletteId;
  final String label;
  final String colorHex;
  final double weight;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  RouletteItemModel copyWith({
    int? id,
    int? rouletteId,
    String? label,
    String? colorHex,
    double? weight,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouletteItemModel(
      id: id ?? this.id,
      rouletteId: rouletteId ?? this.rouletteId,
      label: label ?? this.label,
      colorHex: colorHex ?? this.colorHex,
      weight: weight ?? this.weight,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      'roulette_id': rouletteId,
      'label': label,
      'color_hex': colorHex,
      'weight': weight,
      'sort_order': sortOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory RouletteItemModel.fromMap(Map<String, dynamic> map) {
    return RouletteItemModel(
      id: map['id'] as int?,
      rouletteId: map['roulette_id'] as int,
      label: map['label'] as String? ?? '',
      colorHex: map['color_hex'] as String? ?? '#FFFFFF',
      weight: (map['weight'] as num?)?.toDouble() ?? 1.0,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
