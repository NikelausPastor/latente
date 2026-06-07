import 'enums.dart';

class Film {
  const Film({
    required this.id,
    required this.brand,
    required this.name,
    required this.nominalIso,
    required this.format,
    required this.notes,
    required this.supportsPushPull,
    required this.recommendedPushPullIso,
  });

  final String id;
  final String brand;
  final String name;
  final int nominalIso;
  final FilmFormat format;
  final String notes;
  final bool supportsPushPull;
  final List<int> recommendedPushPullIso;

  String get displayName => '$brand $name';

  Film copyWith({
    String? id,
    String? brand,
    String? name,
    int? nominalIso,
    FilmFormat? format,
    String? notes,
    bool? supportsPushPull,
    List<int>? recommendedPushPullIso,
  }) {
    return Film(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      nominalIso: nominalIso ?? this.nominalIso,
      format: format ?? this.format,
      notes: notes ?? this.notes,
      supportsPushPull: supportsPushPull ?? this.supportsPushPull,
      recommendedPushPullIso:
          recommendedPushPullIso ?? this.recommendedPushPullIso,
    );
  }

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      id: json['id'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nominalIso: (json['nominalIso'] as num?)?.toInt() ?? 400,
      format: filmFormatFromName(json['format'] as String?),
      notes: json['notes'] as String? ?? '',
      supportsPushPull: json['supportsPushPull'] as bool? ?? false,
      recommendedPushPullIso: (json['recommendedPushPullIso'] as List? ?? [])
          .map((item) => (item as num).toInt())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'name': name,
      'nominalIso': nominalIso,
      'format': format.name,
      'notes': notes,
      'supportsPushPull': supportsPushPull,
      'recommendedPushPullIso': recommendedPushPullIso,
    };
  }
}
