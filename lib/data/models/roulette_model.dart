class RouletteModel {
  RouletteModel({
    this.id,
    required this.title,
    this.description = '',
    this.colorHex = '#FFFFFF',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final int? id;
  final String title;
  final String description;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  RouletteModel copyWith({
    int? id,
    String? title,
    String? description,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouletteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'color_hex': colorHex,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory RouletteModel.fromMap(Map<String, dynamic> map) {
    return RouletteModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      colorHex: map['color_hex'] as String? ?? '#FFFFFF',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
