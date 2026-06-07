import 'enums.dart';

class DevelopmentSession {
  const DevelopmentSession({
    required this.id,
    required this.date,
    required this.filmId,
    required this.filmName,
    required this.exposedIso,
    required this.developerId,
    required this.developerName,
    required this.dilution,
    required this.volumeMl,
    required this.temperature,
    required this.chemicalUses,
    required this.agitationMethod,
    required this.tank,
    required this.filmFormat,
    required this.stockRollNumber,
    required this.finalTimeSeconds,
    required this.resultNotes,
    required this.rating,
    required this.referenceImagePath,
  });

  final String id;
  final DateTime date;
  final String filmId;
  final String filmName;
  final int exposedIso;
  final String developerId;
  final String developerName;
  final String dilution;
  final int volumeMl;
  final double temperature;
  final int chemicalUses;
  final AgitationMethod agitationMethod;
  final String tank;
  final FilmFormat filmFormat;
  final int stockRollNumber;
  final int finalTimeSeconds;
  final String resultNotes;
  final ResultRating rating;
  final String? referenceImagePath;

  DevelopmentSession copyWith({
    String? id,
    DateTime? date,
    String? filmId,
    String? filmName,
    int? exposedIso,
    String? developerId,
    String? developerName,
    String? dilution,
    int? volumeMl,
    double? temperature,
    int? chemicalUses,
    AgitationMethod? agitationMethod,
    String? tank,
    FilmFormat? filmFormat,
    int? stockRollNumber,
    int? finalTimeSeconds,
    String? resultNotes,
    ResultRating? rating,
    String? referenceImagePath,
  }) {
    return DevelopmentSession(
      id: id ?? this.id,
      date: date ?? this.date,
      filmId: filmId ?? this.filmId,
      filmName: filmName ?? this.filmName,
      exposedIso: exposedIso ?? this.exposedIso,
      developerId: developerId ?? this.developerId,
      developerName: developerName ?? this.developerName,
      dilution: dilution ?? this.dilution,
      volumeMl: volumeMl ?? this.volumeMl,
      temperature: temperature ?? this.temperature,
      chemicalUses: chemicalUses ?? this.chemicalUses,
      agitationMethod: agitationMethod ?? this.agitationMethod,
      tank: tank ?? this.tank,
      filmFormat: filmFormat ?? this.filmFormat,
      stockRollNumber: stockRollNumber ?? this.stockRollNumber,
      finalTimeSeconds: finalTimeSeconds ?? this.finalTimeSeconds,
      resultNotes: resultNotes ?? this.resultNotes,
      rating: rating ?? this.rating,
      referenceImagePath: referenceImagePath ?? this.referenceImagePath,
    );
  }

  factory DevelopmentSession.fromJson(Map<String, dynamic> json) {
    return DevelopmentSession(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      filmId: json['filmId'] as String? ?? '',
      filmName: json['filmName'] as String? ?? '',
      exposedIso: (json['exposedIso'] as num?)?.toInt() ?? 400,
      developerId: json['developerId'] as String? ?? '',
      developerName: json['developerName'] as String? ?? '',
      dilution: json['dilution'] as String? ?? '',
      volumeMl: (json['volumeMl'] as num?)?.toInt() ?? 300,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 20,
      chemicalUses: (json['chemicalUses'] as num?)?.toInt() ?? 0,
      agitationMethod:
          agitationMethodFromName(json['agitationMethod'] as String?),
      tank: json['tank'] as String? ?? '',
      filmFormat: filmFormatFromName(json['filmFormat'] as String?),
      stockRollNumber: (json['stockRollNumber'] as num?)?.toInt() ??
          (json['chemicalUses'] as num?)?.toInt() ??
          1,
      finalTimeSeconds: (json['finalTimeSeconds'] as num?)?.toInt() ?? 0,
      resultNotes: json['resultNotes'] as String? ?? '',
      rating: resultRatingFromName(json['rating'] as String?),
      referenceImagePath: json['referenceImagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'filmId': filmId,
      'filmName': filmName,
      'exposedIso': exposedIso,
      'developerId': developerId,
      'developerName': developerName,
      'dilution': dilution,
      'volumeMl': volumeMl,
      'temperature': temperature,
      'chemicalUses': chemicalUses,
      'agitationMethod': agitationMethod.name,
      'tank': tank,
      'filmFormat': filmFormat.name,
      'stockRollNumber': stockRollNumber,
      'finalTimeSeconds': finalTimeSeconds,
      'resultNotes': resultNotes,
      'rating': rating.name,
      'referenceImagePath': referenceImagePath,
    };
  }
}
