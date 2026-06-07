enum FilmFormat {
  thirtyFiveMm,
  oneTwenty,
  largeFormat,
  other,
}

enum ChemicalType {
  developer,
  stop,
  fixer,
  wettingAgent,
}

enum WearRule {
  none,
  addSecondsPerPreviousUse,
  addMinutesPerPreviousUse,
}

enum SourceType {
  manufacturer,
  user,
  community,
  estimated,
}

enum ConfidenceLevel {
  high,
  medium,
  low,
}

enum AgitationMethod {
  manualStandard,
  continuousRotaryNoPrebath,
}

enum TemperatureCompensationMode {
  exactManufacturer,
  estimatedFormula,
}

enum ResultRating {
  good,
  underdeveloped,
  overdeveloped,
  highContrast,
  lowContrast,
  toReview,
}

extension FilmFormatLabel on FilmFormat {
  String get label {
    switch (this) {
      case FilmFormat.thirtyFiveMm:
        return '35mm';
      case FilmFormat.oneTwenty:
        return '120';
      case FilmFormat.largeFormat:
        return 'Grande formato';
      case FilmFormat.other:
        return 'Altro';
    }
  }
}

extension ChemicalTypeLabel on ChemicalType {
  String get label {
    switch (this) {
      case ChemicalType.developer:
        return 'Rivelatore';
      case ChemicalType.stop:
        return 'Arresto';
      case ChemicalType.fixer:
        return 'Fissaggio';
      case ChemicalType.wettingAgent:
        return 'Imbibente';
    }
  }
}

extension WearRuleLabel on WearRule {
  String get label {
    switch (this) {
      case WearRule.none:
        return 'Nessuna';
      case WearRule.addSecondsPerPreviousUse:
        return '+ secondi per utilizzo';
      case WearRule.addMinutesPerPreviousUse:
        return '+ minuti per utilizzo';
    }
  }
}

extension ResultRatingLabel on ResultRating {
  String get label {
    switch (this) {
      case ResultRating.good:
        return 'Ok';
      case ResultRating.underdeveloped:
        return 'Sotto-sviluppato';
      case ResultRating.overdeveloped:
        return 'Sovra-sviluppato';
      case ResultRating.highContrast:
        return 'Contrasto alto';
      case ResultRating.lowContrast:
        return 'Contrasto basso';
      case ResultRating.toReview:
        return 'Da verificare';
    }
  }
}

extension SourceTypeLabel on SourceType {
  String get label {
    switch (this) {
      case SourceType.manufacturer:
        return 'Produttore';
      case SourceType.user:
        return 'Preset personale';
      case SourceType.community:
        return 'Community';
      case SourceType.estimated:
        return 'Stimato';
    }
  }
}

extension ConfidenceLevelLabel on ConfidenceLevel {
  String get label {
    switch (this) {
      case ConfidenceLevel.high:
        return 'Alta';
      case ConfidenceLevel.medium:
        return 'Media';
      case ConfidenceLevel.low:
        return 'Bassa';
    }
  }
}

extension AgitationMethodLabel on AgitationMethod {
  String get label {
    switch (this) {
      case AgitationMethod.manualStandard:
        return 'Manuale standard';
      case AgitationMethod.continuousRotaryNoPrebath:
        return 'Rotativa / continua senza prebagno';
    }
  }
}

extension TemperatureCompensationModeLabel on TemperatureCompensationMode {
  String get label {
    switch (this) {
      case TemperatureCompensationMode.exactManufacturer:
        return 'Esatta produttore';
      case TemperatureCompensationMode.estimatedFormula:
        return 'Stimata';
    }
  }
}

FilmFormat filmFormatFromName(String? value) {
  return FilmFormat.values.firstWhere(
    (item) => item.name == value,
    orElse: () => FilmFormat.thirtyFiveMm,
  );
}

ChemicalType chemicalTypeFromName(String? value) {
  return ChemicalType.values.firstWhere(
    (item) => item.name == value,
    orElse: () => ChemicalType.developer,
  );
}

WearRule wearRuleFromName(String? value) {
  return WearRule.values.firstWhere(
    (item) => item.name == value,
    orElse: () => WearRule.none,
  );
}

SourceType sourceTypeFromName(String? value) {
  return SourceType.values.firstWhere(
    (item) => item.name == value,
    orElse: () => SourceType.user,
  );
}

ConfidenceLevel confidenceLevelFromName(String? value) {
  return ConfidenceLevel.values.firstWhere(
    (item) => item.name == value,
    orElse: () => ConfidenceLevel.medium,
  );
}

AgitationMethod agitationMethodFromName(String? value) {
  return AgitationMethod.values.firstWhere(
    (item) => item.name == value,
    orElse: () => AgitationMethod.manualStandard,
  );
}

TemperatureCompensationMode temperatureCompensationModeFromName(String? value) {
  return TemperatureCompensationMode.values.firstWhere(
    (item) => item.name == value,
    orElse: () => TemperatureCompensationMode.exactManufacturer,
  );
}

ResultRating resultRatingFromName(String? value) {
  return ResultRating.values.firstWhere(
    (item) => item.name == value,
    orElse: () => ResultRating.toReview,
  );
}
