import 'package:flutter/material.dart';

import '../models/calculation_result.dart';
import '../models/chemical.dart';
import '../models/development_session.dart';
import '../models/enums.dart';
import '../models/film.dart';
import '../services/app_state.dart';
import '../services/development_calculator.dart';
import '../services/time_formatter.dart';
import '../theme/app_theme.dart';
import '../widgets/info_row.dart';
import '../widgets/latente_card.dart';
import '../widgets/latente_list_view.dart';
import '../widgets/section_title.dart';
import '../widgets/warning_box.dart';
import 'timer_screen.dart';

class NewDevelopmentScreen extends StatefulWidget {
  const NewDevelopmentScreen({this.initialSession, super.key});

  final DevelopmentSession? initialSession;

  @override
  State<NewDevelopmentScreen> createState() => _NewDevelopmentScreenState();
}

class _NewDevelopmentScreenState extends State<NewDevelopmentScreen> {
  final _temperatureController = TextEditingController(text: '20.0');
  final _volumeController = TextEditingController(text: '300');
  final _stockRollController = TextEditingController(text: '1');
  final _exposedIsoController = TextEditingController();

  bool _initialized = false;
  late String _filmId;
  late String _developerId;
  late String _dilution;
  FilmFormat _filmFormat = FilmFormat.thirtyFiveMm;
  AgitationMethod _agitationMethod = AgitationMethod.manualStandard;
  TemperatureCompensationMode _temperatureMode =
      TemperatureCompensationMode.exactManufacturer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final appState = LatenteScope.of(context);
    final developers = _developers(appState);
    if (appState.films.isEmpty || developers.isEmpty) {
      _initialized = true;
      return;
    }

    final fallbackFilm = appState.films.first;
    final fallbackDeveloper = developers.first;
    final initialSession = widget.initialSession;
    final initialFilm = initialSession == null
        ? fallbackFilm
        : _findFilm(appState.films, initialSession) ?? fallbackFilm;
    final initialDeveloper = initialSession == null
        ? fallbackDeveloper
        : _findDeveloper(developers, initialSession) ?? fallbackDeveloper;

    _filmId = initialFilm.id;
    _developerId = initialDeveloper.id;
    _dilution = _initialDilution(initialDeveloper, initialSession);
    _filmFormat = initialSession?.filmFormat ?? initialFilm.format;
    _agitationMethod =
        initialSession?.agitationMethod ?? AgitationMethod.manualStandard;
    _exposedIsoController.text =
        (initialSession?.exposedIso ?? initialFilm.nominalIso).toString();
    _temperatureController.text =
        (initialSession?.temperature ?? 20).toStringAsFixed(1);
    _volumeController.text = (initialSession?.volumeMl ?? 300).toString();
    _stockRollController.text =
        (initialSession?.stockRollNumber ?? 1).toString();
    _initialized = true;
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _volumeController.dispose();
    _stockRollController.dispose();
    _exposedIsoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = LatenteScope.of(context);
    final developers = _developers(appState);

    if (appState.films.isEmpty || developers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nuovo sviluppo')),
        body: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Servono almeno una pellicola e un rivelatore per calcolare uno sviluppo.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final film = appState.films.firstWhere(
      (item) => item.id == _filmId,
      orElse: () => appState.films.first,
    );
    final developer = developers.firstWhere(
      (item) => item.id == _developerId,
      orElse: () => developers.first,
    );
    final dilutions =
        developer.dilutions.isEmpty ? <String>[_dilution] : developer.dilutions;
    if (!dilutions.contains(_dilution)) {
      _dilution = dilutions.first;
    }

    final exposedIso =
        int.tryParse(_exposedIsoController.text.trim()) ?? film.nominalIso;
    final temperature =
        double.tryParse(_temperatureController.text.trim()) ?? 20;
    final finalVolumeMl = double.tryParse(_volumeController.text.trim()) ?? 300;
    final stockRollNumber = int.tryParse(_stockRollController.text.trim()) ?? 1;

    final calculation = DevelopmentCalculator().calculate(
      film: film,
      developer: developer,
      recipes: appState.recipes,
      exposedIso: exposedIso,
      dilution: _dilution,
      realTemperature: temperature,
      stockRollNumber: stockRollNumber,
      finalVolumeMl: finalVolumeMl,
      agitationMethod: _agitationMethod,
      temperatureMode: _temperatureMode,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo sviluppo')),
      body: LatenteListView(
        children: [
          if (widget.initialSession != null)
            const LatenteCard(
              child: Text(
                'Dati ripresi dal diario: controlla condizioni e fonte prima di avviare il timer.',
              ),
            ),
          const SectionTitle(
            title: 'Calcolo sviluppo',
            subtitle:
                'Seleziona materiali, condizioni reali e fonte del calcolo.',
          ),
          LatenteCard(
            child: Column(
              children: [
                DropdownButtonFormField<FilmFormat>(
                  initialValue: _filmFormat,
                  decoration: const InputDecoration(labelText: 'Formato'),
                  items: const [
                    FilmFormat.thirtyFiveMm,
                    FilmFormat.oneTwenty,
                    FilmFormat.largeFormat,
                  ]
                      .map(
                        (format) => DropdownMenuItem(
                          value: format,
                          child: Text(format.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _filmFormat = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: film.id,
                  decoration: const InputDecoration(labelText: 'Pellicola'),
                  isExpanded: true,
                  items: appState.films
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final selected =
                          appState.films.firstWhere((item) => item.id == value);
                      setState(() {
                        _filmId = value;
                        _filmFormat = selected.format;
                        _exposedIsoController.text =
                            selected.nominalIso.toString();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _exposedIsoController,
                  decoration:
                      const InputDecoration(labelText: 'EI / ISO esposto'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: developer.id,
                  decoration: const InputDecoration(labelText: 'Rivelatore'),
                  isExpanded: true,
                  items: developers
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final selected =
                          developers.firstWhere((item) => item.id == value);
                      setState(() {
                        _developerId = value;
                        _dilution = selected.dilutions.isNotEmpty
                            ? selected.dilutions.first
                            : '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _dilution,
                  decoration: const InputDecoration(labelText: 'Diluizione'),
                  items: dilutions
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _dilution = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _volumeController,
                        decoration: const InputDecoration(
                          labelText: 'Volume finale ml',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _temperatureController,
                        decoration: const InputDecoration(
                          labelText: 'Temperatura reale C',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AgitationMethod>(
                  initialValue: _agitationMethod,
                  decoration: const InputDecoration(labelText: 'Agitazione'),
                  isExpanded: true,
                  items: AgitationMethod.values
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _agitationMethod = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TemperatureCompensationMode>(
                  initialValue: _temperatureMode,
                  decoration: const InputDecoration(
                    labelText: 'Correzione temperatura',
                  ),
                  isExpanded: true,
                  items: TemperatureCompensationMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _temperatureMode = value);
                    }
                  },
                ),
                if (DevelopmentCalculator.isStockDilution(_dilution)) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stockRollController,
                    decoration: const InputDecoration(
                      labelText: 'Numero rullino nello stock',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
            ),
          ),
          _DeveloperProfileCard(developer: developer),
          WarningBox(messages: calculation.warnings),
          _CalculationCard(
            calculation: calculation,
            temperature: temperature,
            agitationMethod: _agitationMethod,
            stockRollNumber: stockRollNumber,
            dilution: _dilution,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: calculation.finalTimeSeconds > 0
                ? () => _openTimer(
                      context: context,
                      film: film,
                      developer: developer,
                      exposedIso: exposedIso,
                      temperature: temperature,
                      volumeMl: finalVolumeMl.round(),
                      stockRollNumber: stockRollNumber,
                      calculation: calculation,
                    )
                : null,
            icon: const Icon(Icons.timer_outlined),
            label: const Text('Avvia timer lavorazione'),
          ),
        ],
      ),
    );
  }

  static List<Chemical> _developers(LatenteAppState appState) {
    return appState.chemicals
        .where((chemical) => chemical.type == ChemicalType.developer)
        .toList();
  }

  static Film? _findFilm(List<Film> films, DevelopmentSession session) {
    for (final film in films) {
      if (film.id == session.filmId || film.displayName == session.filmName) {
        return film;
      }
    }
    return null;
  }

  static Chemical? _findDeveloper(
    List<Chemical> developers,
    DevelopmentSession session,
  ) {
    for (final developer in developers) {
      if (developer.id == session.developerId ||
          developer.name == session.developerName) {
        return developer;
      }
    }
    return null;
  }

  static String _initialDilution(
    Chemical developer,
    DevelopmentSession? session,
  ) {
    if (session != null && developer.dilutions.contains(session.dilution)) {
      return session.dilution;
    }
    if (developer.dilutions.isNotEmpty) {
      return developer.dilutions.first;
    }
    return session?.dilution ?? '';
  }

  void _openTimer({
    required BuildContext context,
    required Film film,
    required Chemical developer,
    required int exposedIso,
    required double temperature,
    required int volumeMl,
    required int stockRollNumber,
    required CalculationResult calculation,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          film: film,
          developer: developer,
          exposedIso: exposedIso,
          dilution: _dilution,
          volumeMl: volumeMl,
          temperature: temperature,
          chemicalUses: stockRollNumber,
          stockRollNumber: stockRollNumber,
          filmFormat: _filmFormat,
          agitationMethod: _agitationMethod,
          calculation: calculation,
        ),
      ),
    );
  }
}

class _DeveloperProfileCard extends StatelessWidget {
  const _DeveloperProfileCard({required this.developer});

  final Chemical developer;

  @override
  Widget build(BuildContext context) {
    if (developer.description.trim().isEmpty &&
        developer.notes.isEmpty &&
        developer.capacityNotes.isEmpty) {
      return const SizedBox.shrink();
    }

    return LatenteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profilo rivelatore',
              style: Theme.of(context).textTheme.titleMedium),
          if (developer.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(developer.description),
          ],
          if (developer.capacityNotes.isNotEmpty) ...[
            const Divider(),
            for (final note in developer.capacityNotes) Text('- $note'),
          ],
          if (developer.notes.isNotEmpty) ...[
            const Divider(),
            for (final note in developer.notes) Text('- $note'),
          ],
        ],
      ),
    );
  }
}

class _CalculationCard extends StatelessWidget {
  const _CalculationCard({
    required this.calculation,
    required this.temperature,
    required this.agitationMethod,
    required this.stockRollNumber,
    required this.dilution,
  });

  final CalculationResult calculation;
  final double temperature;
  final AgitationMethod agitationMethod;
  final int stockRollNumber;
  final String dilution;

  @override
  Widget build(BuildContext context) {
    final recipe = calculation.recipe;
    final available = calculation.isAvailable;

    return LatenteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risultato', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            available ? 'Ricetta esatta trovata.' : 'non disponibile',
            style: TextStyle(
              color: available ? AppTheme.softBlue : AppTheme.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Divider(),
          InfoRow(
            label: recipe == null
                ? 'Tempo base'
                : 'Tempo base a ${recipe.baseTemperatureC.toStringAsFixed(1)} C',
            value: _timeOrUnavailable(calculation.baseTimeSeconds, available),
          ),
          InfoRow(
            label: DevelopmentCalculator.isStockDilution(dilution)
                ? 'Riuso stock rullino $stockRollNumber'
                : 'Riuso stock',
            value: available ? _reuseValue() : 'non disponibile',
          ),
          InfoRow(
            label: 'Correzione temperatura ${temperature.toStringAsFixed(1)} C',
            value: _stepValue(
              calculation.afterTemperatureSeconds,
              calculation.afterReuseSeconds,
              available,
            ),
          ),
          InfoRow(
            label: 'Agitazione',
            value: available
                ? '${agitationMethod.label} (${TimeFormatter.minutesSeconds(calculation.afterAgitationSeconds)})'
                : 'non disponibile',
          ),
          const Divider(),
          InfoRow(
            label: 'Stock',
            value: calculation.dilutionVolume.available
                ? '${_formatMl(calculation.stockMl)} ml'
                : 'non disponibile',
          ),
          InfoRow(
            label: 'Acqua',
            value: calculation.dilutionVolume.available
                ? '${_formatMl(calculation.waterMl)} ml'
                : 'non disponibile',
          ),
          const Divider(),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tempo finale',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                _timeOrUnavailable(calculation.finalTimeSeconds, available),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: available ? AppTheme.softBlue : AppTheme.warning,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          if (calculation.sourceInfo.isNotEmpty) ...[
            const Divider(),
            Text('Fonti', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final source in calculation.sourceInfo)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${source.sourceType.label}: ${source.sourceName} (${source.confidence.label})',
                ),
              ),
          ],
          if (calculation.notes.isNotEmpty) ...[
            const Divider(),
            Text('Note operative',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final note in calculation.notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('- $note'),
              ),
          ],
        ],
      ),
    );
  }

  String _reuseValue() {
    if (!DevelopmentCalculator.isStockDilution(dilution)) {
      return 'non applicato';
    }
    if (calculation.afterReuseSeconds == calculation.baseTimeSeconds) {
      return 'non applicato';
    }
    return TimeFormatter.minutesSeconds(calculation.afterReuseSeconds);
  }

  static String _stepValue(int value, int previousValue, bool available) {
    if (!available) {
      return 'non disponibile';
    }
    if (value == previousValue) {
      return 'non applicata';
    }
    return TimeFormatter.minutesSeconds(value);
  }

  static String _timeOrUnavailable(int value, bool available) {
    if (!available || value <= 0) {
      return 'non disponibile';
    }
    return TimeFormatter.minutesSeconds(value);
  }

  static String _formatMl(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}
