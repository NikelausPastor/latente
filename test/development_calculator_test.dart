import 'package:flutter_test/flutter_test.dart';
import 'package:latente/data/sample_data.dart';
import 'package:latente/models/calculation_result.dart';
import 'package:latente/models/enums.dart';
import 'package:latente/services/development_calculator.dart';
import 'package:latente/services/time_formatter.dart';

void main() {
  group('TimeFormatter', () {
    test('parses MM:SS to seconds', () {
      expect(TimeFormatter.parseMinutesSeconds('8:00'), 480);
      expect(TimeFormatter.parseMinutesSeconds('06:30'), 390);
    });

    test('formats seconds to MM:SS', () {
      expect(TimeFormatter.minutesSeconds(480), '8:00');
      expect(TimeFormatter.minutesSeconds(390), '6:30');
    });

    test('rounds to nearest 15 seconds', () {
      expect(TimeFormatter.roundToNearest15Seconds(487), 480);
      expect(TimeFormatter.roundToNearest15Seconds(488), 495);
    });
  });

  group('Dilution volumes', () {
    test('calculates 1+0', () {
      final result = DevelopmentCalculator.calculateDilutionVolumes(300, '1+0');
      expect(result.stockMl, 300);
      expect(result.waterMl, 0);
    });

    test('calculates 1+1', () {
      final result300 =
          DevelopmentCalculator.calculateDilutionVolumes(300, '1+1');
      final result600 =
          DevelopmentCalculator.calculateDilutionVolumes(600, '1+1');
      expect(result300.stockMl, 150);
      expect(result300.waterMl, 150);
      expect(result600.stockMl, 300);
      expect(result600.waterMl, 300);
    });

    test('calculates 1+3', () {
      final result300 =
          DevelopmentCalculator.calculateDilutionVolumes(300, '1+3');
      final result500 =
          DevelopmentCalculator.calculateDilutionVolumes(500, '1+3');
      expect(result300.stockMl, 75);
      expect(result300.waterMl, 225);
      expect(result500.stockMl, 125);
      expect(result500.waterMl, 375);
    });
  });

  group('Microphen data', () {
    test('HP5 Plus EI 400 1+0 is 6:30', () {
      final result = _calculate(
        filmId: 'film_ilford_hp5_plus_400',
        ei: 400,
        dilution: '1+0',
      );

      expect(result.baseTimeSeconds, 390);
      expect(result.finalTimeSeconds, 390);
      expect(result.recipe?.sourceType, SourceType.manufacturer);
      expect(result.recipe?.confidence, ConfidenceLevel.high);
    });

    test('HP5 Plus EI 400 1+1 is 12:00', () {
      final result = _calculate(
        filmId: 'film_ilford_hp5_plus_400',
        ei: 400,
        dilution: '1+1',
      );

      expect(result.baseTimeSeconds, 720);
      expect(result.finalTimeSeconds, 720);
    });

    test('HP5 Plus EI 400 1+3 is 23:00', () {
      final result = _calculate(
        filmId: 'film_ilford_hp5_plus_400',
        ei: 400,
        dilution: '1+3',
      );

      expect(result.baseTimeSeconds, 1380);
      expect(result.finalTimeSeconds, 1380);
    });

    test('Tri-X EI 400 1+1 is 11:00 from community data', () {
      final result = _calculate(
        filmId: 'film_kodak_tri_x_400',
        ei: 400,
        dilution: '1+1',
      );

      expect(result.baseTimeSeconds, 660);
      expect(result.finalTimeSeconds, 660);
      expect(result.recipe?.sourceType, SourceType.community);
    });

    test('missing time does not crash and is unavailable', () {
      final result = _calculate(
        filmId: 'film_kodak_plus_x',
        ei: 125,
        dilution: '1+0',
      );

      expect(result.isAvailable, isFalse);
      expect(result.finalTimeSeconds, 0);
      expect(result.warnings, isNotEmpty);
    });
  });

  group('Adjustments', () {
    test('stock reuse roll 3 is +20%', () {
      final result = DevelopmentCalculator.adjustForStockReuse(600, 3);
      expect(result.available, isTrue);
      expect(result.adjustedTimeSeconds, 720);
    });

    test('does not reuse 1+1', () {
      final result = _calculate(
        filmId: 'film_ilford_hp5_plus_400',
        ei: 400,
        dilution: '1+1',
        stockRollNumber: 3,
      );

      expect(result.afterReuseSeconds, result.baseTimeSeconds);
      expect(
        result.warnings,
        contains('Riuso richiesto per 1+1 o 1+3: non applicato.'),
      );
    });

    test('continuous agitation reduces time by 15%', () {
      expect(DevelopmentCalculator.adjustForContinuousAgitation(600), 510);
    });

    test('warns if final time is below 5 minutes', () {
      final result = _calculate(
        filmId: 'film_fuji_neopan_1600',
        ei: 1600,
        dilution: '1+0',
      );

      expect(result.finalTimeSeconds, 210);
      expect(
        result.warnings,
        contains(
          'Tempi finali sotto i 5 minuti non sono raccomandati per rischio di sviluppo non uniforme.',
        ),
      );
    });
  });

  group('Temperature compensation', () {
    test('exact lookup maps 8:00 at 20 C to 5:30 at 24 C', () {
      final result = DevelopmentCalculator.getExactTemperatureCompensation(
        480,
        24,
      );

      expect(result.available, isTrue);
      expect(result.correctedTimeSeconds, 330);
      expect(result.sourceType, SourceType.manufacturer);
      expect(result.roundedToSeconds, 15);
    });

    test('exact lookup warns below 5:00', () {
      final result = DevelopmentCalculator.getExactTemperatureCompensation(
        240,
        24,
      );

      expect(result.available, isTrue);
      expect(result.warning, isNotNull);
    });

    test('temperature not in lookup does not crash', () {
      final result = DevelopmentCalculator.getExactTemperatureCompensation(
        480,
        23,
      );

      expect(result.available, isFalse);
      expect(result.warning, isNotNull);
    });

    test('exact mode keeps time and warns when lookup is unavailable', () {
      final result = _calculate(
        filmId: 'film_ilford_hp5_plus_400',
        ei: 400,
        dilution: '1+0',
        temperature: 23,
      );

      expect(result.afterTemperatureSeconds, result.afterReuseSeconds);
      expect(
        result.warnings,
        contains(
            'Correzione esatta non disponibile per questo tempo/temperatura.'),
      );
    });

    test('estimated mode is marked as estimated', () {
      final result = _calculate(
        filmId: 'film_ilford_hp5_plus_400',
        ei: 400,
        dilution: '1+0',
        temperature: 21,
        temperatureMode: TemperatureCompensationMode.estimatedFormula,
      );

      expect(
          result.sourceInfo
              .any((item) => item.sourceType == SourceType.estimated),
          isTrue);
      expect(result.warnings, contains('Modalita temperatura stimata usata.'));
    });
  });
}

CalculationResult _calculate({
  required String filmId,
  required int ei,
  required String dilution,
  double temperature = 20,
  int stockRollNumber = 1,
  AgitationMethod agitationMethod = AgitationMethod.manualStandard,
  TemperatureCompensationMode temperatureMode =
      TemperatureCompensationMode.exactManufacturer,
}) {
  final data = SampleData.create();
  final film = data.films.firstWhere((item) => item.id == filmId);
  final developer = data.chemicals
      .firstWhere((item) => item.id == 'chemical_ilford_microphen');

  return DevelopmentCalculator().calculate(
    film: film,
    developer: developer,
    recipes: data.recipes,
    exposedIso: ei,
    dilution: dilution,
    realTemperature: temperature,
    stockRollNumber: stockRollNumber,
    finalVolumeMl: 300,
    agitationMethod: agitationMethod,
    temperatureMode: temperatureMode,
  );
}
