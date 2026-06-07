import '../models/calculation_result.dart';
import '../models/chemical.dart';
import '../models/development_recipe.dart';
import '../models/enums.dart';
import '../models/film.dart';
import 'time_formatter.dart';

class DevelopmentCalculator {
  CalculationResult calculate({
    required Film film,
    required Chemical developer,
    required List<DevelopmentRecipe> recipes,
    required int exposedIso,
    required String dilution,
    required double realTemperature,
    required int stockRollNumber,
    required double finalVolumeMl,
    required AgitationMethod agitationMethod,
    required TemperatureCompensationMode temperatureMode,
  }) {
    final warnings = <String>[];
    final notes = <String>[];
    final normalizedDilution = normalizeDilution(dilution);
    final dilutionVolume = calculateDilutionVolumes(finalVolumeMl, dilution);
    if (dilutionVolume.warning != null) {
      warnings.add(dilutionVolume.warning!);
    }

    if (realTemperature < 18 || realTemperature > 24) {
      warnings.add('Temperatura fuori dal range consigliato 18-24 C.');
    }

    final matches = _findExactRecipes(
      recipes: recipes,
      film: film,
      developer: developer,
      exposedIso: exposedIso,
      dilution: dilution,
    );
    final recipe = _selectRecipe(matches, warnings);
    final exactRecipeFound = recipe != null;
    final baseSeconds = recipe?.baseTimeSeconds ?? 0;

    if (!exactRecipeFound || baseSeconds <= 0) {
      warnings.add(
        'Tempo base non disponibile per questa combinazione film/EI/rivelatore/diluizione.',
      );
    }

    final sourceInfo = matches.map(SourceInfo.fromRecipe).toList();
    if (recipe != null && sourceInfo.isEmpty) {
      sourceInfo.add(SourceInfo.fromRecipe(recipe));
    }

    for (final note in developer.notes) {
      if (note.trim().isNotEmpty) {
        notes.add(note);
      }
    }
    if (recipe != null && recipe.notes.trim().isNotEmpty) {
      notes.add(recipe.notes);
    }
    if (recipe?.sourceType == SourceType.estimated) {
      warnings.add('Il tempo base selezionato e stimato.');
    }

    var afterReuse = baseSeconds;
    if (baseSeconds > 0) {
      if (isStockDilution(normalizedDilution)) {
        final reuse = adjustForStockReuse(baseSeconds, stockRollNumber);
        afterReuse = reuse.adjustedTimeSeconds;
        if (reuse.warning != null) {
          warnings.add(reuse.warning!);
        }
        if (reuse.note != null) {
          notes.add(reuse.note!);
        }
      } else {
        notes.add('Soluzione one-shot consigliata.');
        if (stockRollNumber > 1) {
          warnings.add('Riuso richiesto per 1+1 o 1+3: non applicato.');
        }
      }
    }

    var afterTemperature = afterReuse;
    if (baseSeconds > 0) {
      if ((recipe?.baseTemperatureC ?? 20) != 20 &&
          realTemperature != (recipe?.baseTemperatureC ?? 20)) {
        warnings.add(
          'Correzione temperatura richiesta ma dati insufficienti: il lookup produttore e disponibile solo da 20 C.',
        );
      } else if (temperatureMode ==
          TemperatureCompensationMode.exactManufacturer) {
        final compensation = getExactTemperatureCompensation(
          afterReuse,
          realTemperature,
        );
        if (compensation.available &&
            compensation.correctedTimeSeconds != null) {
          afterTemperature = compensation.correctedTimeSeconds!;
          sourceInfo.add(
            const SourceInfo(
              sourceType: SourceType.manufacturer,
              sourceName: 'ILFORD temperature compensation chart',
              sourceDate: '2002-04',
              confidence: ConfidenceLevel.high,
              notes: 'Valori arrotondati al piu vicino 15 secondi.',
            ),
          );
        } else if (compensation.warning != null) {
          warnings.add(compensation.warning!);
        }
      } else {
        final compensation = estimateTemperatureCompensation(
          afterReuse,
          recipe?.baseTemperatureC ?? 20,
          realTemperature,
        );
        afterTemperature = compensation.correctedTimeSeconds ?? afterReuse;
        warnings.add('Modalita temperatura stimata usata.');
        if (compensation.warning != null) {
          warnings.add(compensation.warning!);
        }
        notes.add(
            'Tempo stimato: verificare con test personali o datasheet produttore.');
        sourceInfo.add(
          const SourceInfo(
            sourceType: SourceType.estimated,
            sourceName: 'Formula stimata 10% per grado C',
            sourceDate: null,
            confidence: ConfidenceLevel.low,
            notes: 'Non sostituisce il lookup produttore quando disponibile.',
          ),
        );
      }
    } else if (realTemperature != 20) {
      warnings.add('Correzione richiesta ma dati insufficienti.');
    }

    var afterAgitation = afterTemperature;
    if (baseSeconds > 0 &&
        agitationMethod == AgitationMethod.continuousRotaryNoPrebath) {
      afterAgitation = adjustForContinuousAgitation(afterTemperature);
      notes.add(
          'Riduzione applicata per agitazione continua / rotativa senza prebagno.');
    }

    final finalSeconds = baseSeconds > 0
        ? TimeFormatter.roundToNearest15Seconds(afterAgitation)
        : 0;

    if (finalSeconds > 0 && finalSeconds < 300) {
      warnings.add(
        'Tempi finali sotto i 5 minuti non sono raccomandati per rischio di sviluppo non uniforme.',
      );
    }

    return CalculationResult(
      recipe: recipe,
      exactRecipeFound: exactRecipeFound,
      baseTimeSeconds: baseSeconds,
      afterReuseSeconds: afterReuse,
      afterTemperatureSeconds: afterTemperature,
      afterAgitationSeconds: afterAgitation,
      finalTimeSeconds: finalSeconds,
      dilutionVolume: dilutionVolume,
      warnings: _deduplicate(warnings),
      notes: _deduplicate(notes),
      sourceInfo: sourceInfo,
    );
  }

  static String normalizeDilution(String dilution) {
    final normalized = dilution.trim().toLowerCase().replaceAll(' ', '');
    if (normalized == 'stock' || normalized == '1+0' || normalized == '1:0') {
      return '1+0';
    }
    return normalized.replaceAll(':', '+');
  }

  static bool isStockDilution(String dilution) {
    return normalizeDilution(dilution) == '1+0';
  }

  static DilutionVolume calculateDilutionVolumes(
    double finalVolumeMl,
    String dilution,
  ) {
    if (finalVolumeMl <= 0) {
      return const DilutionVolume(
        available: false,
        stockMl: 0,
        waterMl: 0,
        warning: 'Volume finale non valido.',
      );
    }

    final normalized = normalizeDilution(dilution);
    final match =
        RegExp(r'^(\d+(?:\.\d+)?)\+(\d+(?:\.\d+)?)$').firstMatch(normalized);
    if (match == null) {
      return DilutionVolume(
        available: false,
        stockMl: 0,
        waterMl: 0,
        warning: 'Calcolo diluizione non disponibile per "$dilution".',
      );
    }

    final stockParts = double.parse(match.group(1)!);
    final waterParts = double.parse(match.group(2)!);
    final totalParts = stockParts + waterParts;
    if (stockParts <= 0 || waterParts < 0 || totalParts <= 0) {
      return DilutionVolume(
        available: false,
        stockMl: 0,
        waterMl: 0,
        warning: 'Diluizione non valida: "$dilution".',
      );
    }

    final stockMl = finalVolumeMl * stockParts / totalParts;
    return DilutionVolume(
      available: true,
      stockMl: stockMl,
      waterMl: finalVolumeMl - stockMl,
      warning: null,
    );
  }

  static StockReuseAdjustment adjustForStockReuse(
    int baseTimeSeconds,
    int rollNumber,
  ) {
    final percentages = <int, double>{
      1: 0,
      2: 0.10,
      3: 0.20,
      4: 0.30,
      5: 0.40,
      10: 0.90,
    };

    if (baseTimeSeconds <= 0) {
      return const StockReuseAdjustment(
        available: false,
        adjustedTimeSeconds: 0,
        sourceType: SourceType.manufacturer,
        confidence: ConfidenceLevel.high,
        warning: 'Tempo base non disponibile.',
        note: null,
      );
    }

    if (rollNumber > 10) {
      return StockReuseAdjustment(
        available: false,
        adjustedTimeSeconds: baseTimeSeconds,
        sourceType: SourceType.manufacturer,
        confidence: ConfidenceLevel.high,
        warning: 'Capacita stock superata / non usare.',
        note: null,
      );
    }

    final percentage = percentages[rollNumber];
    if (percentage == null) {
      return StockReuseAdjustment(
        available: false,
        adjustedTimeSeconds: baseTimeSeconds,
        sourceType: SourceType.manufacturer,
        confidence: ConfidenceLevel.high,
        warning: 'Correzione riuso non disponibile nel riferimento esatto.',
        note: null,
      );
    }

    return StockReuseAdjustment(
      available: true,
      adjustedTimeSeconds: TimeFormatter.roundToNearest15Seconds(
        baseTimeSeconds * (1 + percentage),
      ),
      sourceType: SourceType.manufacturer,
      confidence: ConfidenceLevel.high,
      warning: null,
      note: rollNumber == 1
          ? 'Riuso stock: non applicato.'
          : 'Riuso stock: +${(percentage * 100).round()}%.',
    );
  }

  static TemperatureCompensationResult getExactTemperatureCompensation(
    int baseTimeSeconds,
    double temperatureC,
  ) {
    if (baseTimeSeconds <= 0) {
      return const TemperatureCompensationResult(
        available: false,
        sourceType: SourceType.manufacturer,
        roundedToSeconds: 15,
        confidence: ConfidenceLevel.high,
        warning: 'Tempo base non disponibile.',
      );
    }

    final roundedTemperature = temperatureC.round();
    if ((temperatureC - roundedTemperature).abs() > 0.01) {
      return const TemperatureCompensationResult(
        available: false,
        sourceType: SourceType.manufacturer,
        roundedToSeconds: 15,
        confidence: ConfidenceLevel.high,
        warning:
            'Correzione esatta non disponibile per questo tempo/temperatura.',
      );
    }

    if (roundedTemperature == 20) {
      return TemperatureCompensationResult(
        available: true,
        correctedTimeSeconds: baseTimeSeconds,
        sourceType: SourceType.manufacturer,
        roundedToSeconds: 15,
        confidence: ConfidenceLevel.high,
        warning: baseTimeSeconds < 300
            ? 'Tempi sotto i 5 minuti non sono raccomandati per rischio di sviluppo non uniforme.'
            : null,
      );
    }

    final corrected =
        _exactTemperatureTable[roundedTemperature]?[baseTimeSeconds];
    if (corrected == null) {
      return const TemperatureCompensationResult(
        available: false,
        sourceType: SourceType.manufacturer,
        roundedToSeconds: 15,
        confidence: ConfidenceLevel.high,
        warning:
            'Correzione esatta non disponibile per questo tempo/temperatura.',
      );
    }

    return TemperatureCompensationResult(
      available: true,
      correctedTimeSeconds: corrected,
      sourceType: SourceType.manufacturer,
      roundedToSeconds: 15,
      confidence: ConfidenceLevel.high,
      warning: corrected < 300
          ? 'Tempi sotto i 5 minuti non sono raccomandati per rischio di sviluppo non uniforme.'
          : null,
      note: 'Valore produttore arrotondato al piu vicino 15 secondi.',
    );
  }

  static TemperatureCompensationResult estimateTemperatureCompensation(
    int baseTimeSeconds,
    double fromTemperatureC,
    double toTemperatureC,
  ) {
    if (baseTimeSeconds <= 0) {
      return const TemperatureCompensationResult(
        available: false,
        sourceType: SourceType.estimated,
        roundedToSeconds: 15,
        confidence: ConfidenceLevel.low,
        warning: 'Tempo base non disponibile.',
      );
    }

    final delta = toTemperatureC - fromTemperatureC;
    final factor = delta >= 0 ? 1 - (delta * 0.10) : 1 + (delta.abs() * 0.10);
    final corrected = TimeFormatter.roundToNearest15Seconds(
      baseTimeSeconds * factor.clamp(0.1, 3.0),
    );
    return TemperatureCompensationResult(
      available: true,
      correctedTimeSeconds: corrected,
      sourceType: SourceType.estimated,
      roundedToSeconds: 15,
      confidence: ConfidenceLevel.low,
      warning: corrected < 300
          ? 'Tempi sotto i 5 minuti non sono raccomandati per rischio di sviluppo non uniforme.'
          : null,
      note:
          'Tempo stimato: verificare con test personali o datasheet produttore.',
    );
  }

  static int adjustForContinuousAgitation(int timeSeconds) {
    if (timeSeconds <= 0) {
      return 0;
    }
    return TimeFormatter.roundToNearest15Seconds(timeSeconds * 0.85);
  }

  static List<int> _parseTimes(List<String> values) {
    return values.map(TimeFormatter.parseMinutesSeconds).toList();
  }

  static Map<int, Map<int, int>> _buildTemperatureTable() {
    final table = <int, Map<int, int>>{};
    for (final entry in _temperatureRows.entries) {
      final row = <int, int>{};
      for (var index = 0; index < _base20Times.length; index++) {
        row[_base20Times[index]] = entry.value[index];
      }
      table[entry.key] = row;
    }
    return table;
  }

  static final List<int> _base20Times = _parseTimes([
    '4:00',
    '4:30',
    '5:00',
    '5:30',
    '6:00',
    '6:30',
    '7:00',
    '7:30',
    '8:00',
    '8:30',
    '9:00',
    '9:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
    '21:30',
    '22:00',
    '22:30',
    '23:00',
    '23:30',
    '24:00',
    '24:30',
    '25:00',
  ]);

  static final Map<int, List<int>> _temperatureRows = {
    18: _parseTimes([
      '5:00',
      '5:30',
      '6:00',
      '6:30',
      '7:15',
      '8:00',
      '8:45',
      '9:15',
      '9:45',
      '10:30',
      '11:15',
      '11:45',
      '12:30',
      '13:00',
      '13:45',
      '14:15',
      '14:45',
      '15:15',
      '16:00',
      '16:45',
      '17:15',
      '17:45',
      '18:30',
      '19:15',
      '19:45',
      '20:30',
      '21:00',
      '21:45',
      '22:15',
      '22:45',
      '23:30',
      '24:15',
      '24:45',
      '25:15',
      '26:00',
      '26:30',
      '27:15',
      '27:45',
      '28:15',
      '28:45',
      '29:45',
      '30:15',
      '30:45',
    ]),
    19: _parseTimes([
      '4:30',
      '5:00',
      '5:30',
      '6:00',
      '6:30',
      '7:15',
      '7:45',
      '8:15',
      '8:45',
      '9:30',
      '10:00',
      '10:30',
      '11:15',
      '11:45',
      '12:15',
      '12:45',
      '13:15',
      '13:45',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:45',
      '17:15',
      '17:45',
      '18:30',
      '19:00',
      '19:30',
      '20:00',
      '20:30',
      '21:00',
      '21:45',
      '22:15',
      '22:45',
      '23:30',
      '23:45',
      '24:30',
      '25:00',
      '25:30',
      '26:00',
      '26:45',
      '27:15',
      '27:45',
    ]),
    21: _parseTimes([
      '3:30',
      '4:00',
      '4:30',
      '5:00',
      '5:30',
      '6:00',
      '6:30',
      '6:45',
      '7:15',
      '7:45',
      '8:00',
      '8:30',
      '9:00',
      '9:30',
      '10:00',
      '10:30',
      '10:45',
      '11:15',
      '11:45',
      '12:00',
      '12:30',
      '13:00',
      '13:30',
      '14:00',
      '14:30',
      '14:45',
      '15:15',
      '15:45',
      '16:15',
      '16:45',
      '17:15',
      '17:30',
      '18:00',
      '18:30',
      '19:00',
      '19:30',
      '19:45',
      '20:15',
      '20:45',
      '21:00',
      '21:45',
      '22:00',
      '22:30',
    ]),
    22: _parseTimes([
      '3:15',
      '3:45',
      '4:00',
      '4:30',
      '5:00',
      '5:15',
      '5:45',
      '6:00',
      '6:30',
      '7:00',
      '7:15',
      '7:45',
      '8:00',
      '8:30',
      '9:00',
      '9:15',
      '9:45',
      '10:00',
      '10:30',
      '11:00',
      '11:15',
      '11:45',
      '12:15',
      '12:45',
      '13:00',
      '13:30',
      '13:45',
      '14:15',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:15',
      '16:45',
      '17:00',
      '17:30',
      '17:45',
      '18:15',
      '18:45',
      '19:00',
      '19:30',
      '19:45',
      '20:15',
    ]),
    24: _parseTimes([
      '2:30',
      '3:00',
      '3:15',
      '3:30',
      '4:00',
      '4:30',
      '5:00',
      '5:15',
      '5:30',
      '6:00',
      '6:15',
      '6:30',
      '7:00',
      '7:15',
      '7:30',
      '8:00',
      '8:15',
      '8:45',
      '9:00',
      '9:15',
      '9:45',
      '10:00',
      '10:30',
      '10:45',
      '11:00',
      '11:30',
      '11:45',
      '12:00',
      '12:30',
      '12:45',
      '13:15',
      '13:30',
      '13:45',
      '14:15',
      '14:30',
      '15:00',
      '15:15',
      '15:30',
      '16:00',
      '16:15',
      '16:45',
      '17:00',
      '17:15',
    ]),
  };

  static final Map<int, Map<int, int>> _exactTemperatureTable =
      _buildTemperatureTable();

  List<DevelopmentRecipe> _findExactRecipes({
    required List<DevelopmentRecipe> recipes,
    required Film film,
    required Chemical developer,
    required int exposedIso,
    required String dilution,
  }) {
    final normalizedDilution = normalizeDilution(dilution);
    return recipes
        .where(
          (recipe) =>
              recipe.filmId == film.id &&
              recipe.developerId == developer.id &&
              normalizeDilution(recipe.dilution) == normalizedDilution &&
              recipe.ei == exposedIso,
        )
        .toList();
  }

  DevelopmentRecipe? _selectRecipe(
    List<DevelopmentRecipe> matches,
    List<String> warnings,
  ) {
    if (matches.isEmpty) {
      return null;
    }

    matches.sort((a, b) {
      final sourceOrder = _sourcePriority(a.sourceType)
          .compareTo(_sourcePriority(b.sourceType));
      if (sourceOrder != 0) {
        return sourceOrder;
      }
      return _confidencePriority(a.confidence)
          .compareTo(_confidencePriority(b.confidence));
    });

    final distinctTimes =
        matches.map((recipe) => recipe.baseTimeSeconds).toSet();
    if (distinctTimes.length > 1) {
      warnings.add(
        'Fonti con tempi diversi disponibili: default sulla fonte con priorita piu alta.',
      );
    }
    return matches.first;
  }

  int _sourcePriority(SourceType sourceType) {
    switch (sourceType) {
      case SourceType.manufacturer:
        return 0;
      case SourceType.user:
        return 1;
      case SourceType.community:
        return 2;
      case SourceType.estimated:
        return 3;
    }
  }

  int _confidencePriority(ConfidenceLevel confidence) {
    switch (confidence) {
      case ConfidenceLevel.high:
        return 0;
      case ConfidenceLevel.medium:
        return 1;
      case ConfidenceLevel.low:
        return 2;
    }
  }

  static List<String> _deduplicate(List<String> values) {
    return values.where((value) => value.trim().isNotEmpty).toSet().toList();
  }
}
