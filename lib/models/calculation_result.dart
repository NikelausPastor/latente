import 'development_recipe.dart';
import 'enums.dart';

class SourceInfo {
  const SourceInfo({
    required this.sourceType,
    required this.sourceName,
    required this.sourceDate,
    required this.confidence,
    required this.notes,
  });

  final SourceType sourceType;
  final String sourceName;
  final String? sourceDate;
  final ConfidenceLevel confidence;
  final String notes;

  factory SourceInfo.fromRecipe(DevelopmentRecipe recipe) {
    return SourceInfo(
      sourceType: recipe.sourceType,
      sourceName: recipe.sourceName,
      sourceDate: recipe.sourceDate,
      confidence: recipe.confidence,
      notes: recipe.notes,
    );
  }
}

class DilutionVolume {
  const DilutionVolume({
    required this.available,
    required this.stockMl,
    required this.waterMl,
    required this.warning,
  });

  final bool available;
  final double stockMl;
  final double waterMl;
  final String? warning;
}

class StockReuseAdjustment {
  const StockReuseAdjustment({
    required this.available,
    required this.adjustedTimeSeconds,
    required this.sourceType,
    required this.confidence,
    required this.warning,
    required this.note,
  });

  final bool available;
  final int adjustedTimeSeconds;
  final SourceType sourceType;
  final ConfidenceLevel confidence;
  final String? warning;
  final String? note;
}

class TemperatureCompensationResult {
  const TemperatureCompensationResult({
    required this.available,
    required this.sourceType,
    required this.roundedToSeconds,
    required this.confidence,
    this.correctedTimeSeconds,
    this.warning,
    this.note,
  });

  final bool available;
  final int? correctedTimeSeconds;
  final SourceType sourceType;
  final int roundedToSeconds;
  final ConfidenceLevel confidence;
  final String? warning;
  final String? note;
}

class CalculationResult {
  const CalculationResult({
    required this.recipe,
    required this.exactRecipeFound,
    required this.baseTimeSeconds,
    required this.afterReuseSeconds,
    required this.afterTemperatureSeconds,
    required this.afterAgitationSeconds,
    required this.finalTimeSeconds,
    required this.dilutionVolume,
    required this.warnings,
    required this.notes,
    required this.sourceInfo,
  });

  final DevelopmentRecipe? recipe;
  final bool exactRecipeFound;
  final int baseTimeSeconds;
  final int afterReuseSeconds;
  final int afterTemperatureSeconds;
  final int afterAgitationSeconds;
  final int finalTimeSeconds;
  final DilutionVolume dilutionVolume;
  final List<String> warnings;
  final List<String> notes;
  final List<SourceInfo> sourceInfo;

  bool get isAvailable => exactRecipeFound && baseTimeSeconds > 0;
  double get stockMl => dilutionVolume.stockMl;
  double get waterMl => dilutionVolume.waterMl;

  int get temperatureDeltaSeconds =>
      afterTemperatureSeconds - afterReuseSeconds;
  int get wearDeltaSeconds => afterReuseSeconds - baseTimeSeconds;
  int get agitationDeltaSeconds =>
      afterAgitationSeconds - afterTemperatureSeconds;
  int get pushPullDeltaSeconds => 0;
}
