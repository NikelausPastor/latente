import 'enums.dart';

class DevelopmentRecipe {
  const DevelopmentRecipe({
    required this.id,
    required this.filmId,
    required this.filmBrand,
    required this.filmName,
    required this.nominalIso,
    required this.exposedIso,
    required this.ei,
    required this.developerId,
    required this.developerName,
    required this.dilution,
    required this.baseTemperatureC,
    required this.baseTimeSeconds,
    required this.agitation,
    required this.sourceType,
    required this.sourceName,
    required this.sourceDate,
    required this.notes,
    required this.confidence,
  });

  final String id;
  final String filmId;
  final String filmBrand;
  final String filmName;
  final int nominalIso;
  final int exposedIso;
  final int ei;
  final String developerId;
  final String developerName;
  final String dilution;
  final double baseTemperatureC;
  final int baseTimeSeconds;
  final String agitation;
  final SourceType sourceType;
  final String sourceName;
  final String? sourceDate;
  final String notes;
  final ConfidenceLevel confidence;

  double get referenceTemperature => baseTemperatureC;
  String get source => sourceName;

  DevelopmentRecipe copyWith({
    String? id,
    String? filmId,
    String? filmBrand,
    String? filmName,
    int? nominalIso,
    int? exposedIso,
    int? ei,
    String? developerId,
    String? developerName,
    String? dilution,
    double? baseTemperatureC,
    int? baseTimeSeconds,
    String? agitation,
    SourceType? sourceType,
    String? sourceName,
    String? sourceDate,
    String? notes,
    ConfidenceLevel? confidence,
  }) {
    return DevelopmentRecipe(
      id: id ?? this.id,
      filmId: filmId ?? this.filmId,
      filmBrand: filmBrand ?? this.filmBrand,
      filmName: filmName ?? this.filmName,
      nominalIso: nominalIso ?? this.nominalIso,
      exposedIso: exposedIso ?? this.exposedIso,
      ei: ei ?? this.ei,
      developerId: developerId ?? this.developerId,
      developerName: developerName ?? this.developerName,
      dilution: dilution ?? this.dilution,
      baseTemperatureC: baseTemperatureC ?? this.baseTemperatureC,
      baseTimeSeconds: baseTimeSeconds ?? this.baseTimeSeconds,
      agitation: agitation ?? this.agitation,
      sourceType: sourceType ?? this.sourceType,
      sourceName: sourceName ?? this.sourceName,
      sourceDate: sourceDate ?? this.sourceDate,
      notes: notes ?? this.notes,
      confidence: confidence ?? this.confidence,
    );
  }

  factory DevelopmentRecipe.fromJson(Map<String, dynamic> json) {
    final exposedIso = (json['exposedIso'] as num?)?.toInt() ??
        (json['ei'] as num?)?.toInt() ??
        400;
    final sourceName =
        json['sourceName'] as String? ?? json['source'] as String? ?? '';
    return DevelopmentRecipe(
      id: json['id'] as String? ?? '',
      filmId: json['filmId'] as String? ?? '',
      filmBrand: json['filmBrand'] as String? ?? '',
      filmName: json['filmName'] as String? ?? '',
      nominalIso: (json['nominalIso'] as num?)?.toInt() ?? 400,
      exposedIso: exposedIso,
      ei: (json['ei'] as num?)?.toInt() ?? exposedIso,
      developerId: json['developerId'] as String? ?? '',
      developerName: json['developerName'] as String? ?? '',
      dilution: json['dilution'] as String? ?? '',
      baseTemperatureC: ((json['baseTemperatureC'] as num?) ??
                  (json['referenceTemperature'] as num?))
              ?.toDouble() ??
          20,
      baseTimeSeconds: (json['baseTimeSeconds'] as num?)?.toInt() ?? 480,
      agitation: json['agitation'] as String? ??
          '30 secondi iniziali, poi 10 secondi ogni minuto',
      sourceType: sourceTypeFromName(json['sourceType'] as String?),
      sourceName: sourceName,
      sourceDate: json['sourceDate'] as String?,
      notes: json['notes'] as String? ?? '',
      confidence: confidenceLevelFromName(json['confidence'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filmId': filmId,
      'filmBrand': filmBrand,
      'filmName': filmName,
      'nominalIso': nominalIso,
      'exposedIso': exposedIso,
      'ei': ei,
      'developerId': developerId,
      'developerName': developerName,
      'dilution': dilution,
      'baseTemperatureC': baseTemperatureC,
      'referenceTemperature': baseTemperatureC,
      'baseTimeSeconds': baseTimeSeconds,
      'agitation': agitation,
      'sourceType': sourceType.name,
      'sourceName': sourceName,
      'sourceDate': sourceDate,
      'source': sourceName,
      'notes': notes,
      'confidence': confidence.name,
    };
  }
}
