import 'enums.dart';

class Chemical {
  const Chemical({
    required this.id,
    required this.name,
    required this.type,
    required this.dilutions,
    required this.oneShot,
    required this.maxUses,
    required this.wearRule,
    required this.wearIncrement,
    this.description = '',
    this.preparationSteps = const [],
    this.capacityNotes = const [],
    this.notes = const [],
  });

  final String id;
  final String name;
  final ChemicalType type;
  final List<String> dilutions;
  final bool oneShot;
  final int? maxUses;
  final WearRule wearRule;
  final int wearIncrement;
  final String description;
  final List<String> preparationSteps;
  final List<String> capacityNotes;
  final List<String> notes;

  Chemical copyWith({
    String? id,
    String? name,
    ChemicalType? type,
    List<String>? dilutions,
    bool? oneShot,
    int? maxUses,
    WearRule? wearRule,
    int? wearIncrement,
    String? description,
    List<String>? preparationSteps,
    List<String>? capacityNotes,
    List<String>? notes,
  }) {
    return Chemical(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      dilutions: dilutions ?? this.dilutions,
      oneShot: oneShot ?? this.oneShot,
      maxUses: maxUses ?? this.maxUses,
      wearRule: wearRule ?? this.wearRule,
      wearIncrement: wearIncrement ?? this.wearIncrement,
      description: description ?? this.description,
      preparationSteps: preparationSteps ?? this.preparationSteps,
      capacityNotes: capacityNotes ?? this.capacityNotes,
      notes: notes ?? this.notes,
    );
  }

  factory Chemical.fromJson(Map<String, dynamic> json) {
    return Chemical(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: chemicalTypeFromName(json['type'] as String?),
      dilutions: (json['dilutions'] as List? ?? [])
          .map((item) => item.toString())
          .toList(),
      oneShot: json['oneShot'] as bool? ?? true,
      maxUses: (json['maxUses'] as num?)?.toInt(),
      wearRule: wearRuleFromName(json['wearRule'] as String?),
      wearIncrement: (json['wearIncrement'] as num?)?.toInt() ?? 1,
      description: json['description'] as String? ?? '',
      preparationSteps: (json['preparationSteps'] as List? ?? [])
          .map((item) => item.toString())
          .toList(),
      capacityNotes: (json['capacityNotes'] as List? ?? [])
          .map((item) => item.toString())
          .toList(),
      notes: (json['notes'] as List? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'dilutions': dilutions,
      'oneShot': oneShot,
      'maxUses': maxUses,
      'wearRule': wearRule.name,
      'wearIncrement': wearIncrement,
      'description': description,
      'preparationSteps': preparationSteps,
      'capacityNotes': capacityNotes,
      'notes': notes,
    };
  }
}
