import 'package:flutter/material.dart';

import '../models/calculation_result.dart';
import '../models/chemical.dart';
import '../models/development_session.dart';
import '../models/enums.dart';
import '../models/film.dart';
import '../services/app_state.dart';
import '../services/processing_timer_service.dart';
import '../services/time_formatter.dart';
import '../theme/app_theme.dart';
import '../widgets/info_row.dart';
import '../widgets/latente_card.dart';
import '../widgets/latente_list_view.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({
    required this.film,
    required this.developer,
    required this.exposedIso,
    required this.dilution,
    required this.volumeMl,
    required this.temperature,
    required this.chemicalUses,
    required this.stockRollNumber,
    required this.filmFormat,
    required this.agitationMethod,
    required this.calculation,
    super.key,
  });

  final Film film;
  final Chemical developer;
  final int exposedIso;
  final String dilution;
  final int volumeMl;
  final double temperature;
  final int chemicalUses;
  final int stockRollNumber;
  final FilmFormat filmFormat;
  final AgitationMethod agitationMethod;
  final CalculationResult calculation;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late ProcessingTimerService _timerService;
  final _stopController = TextEditingController(text: '30');
  final _fixerController = TextEditingController(text: '300');
  final _washController = TextEditingController(text: '600');
  final _wettingController = TextEditingController(text: '60');
  final _initialAgitationController = TextEditingController(text: '30');
  final _agitationIntervalController = TextEditingController(text: '60');
  final _agitationDurationController = TextEditingController(text: '10');
  final _tankController = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _timerService = _buildTimerService();
  }

  @override
  void dispose() {
    _timerService.dispose();
    _stopController.dispose();
    _fixerController.dispose();
    _washController.dispose();
    _wettingController.dispose();
    _initialAgitationController.dispose();
    _agitationIntervalController.dispose();
    _agitationDurationController.dispose();
    _tankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timer lavorazione')),
      body: AnimatedBuilder(
        animation: _timerService,
        builder: (context, _) {
          final phase = _timerService.currentPhase;
          final progress = phase.durationSeconds == 0
              ? 1.0
              : 1 - (_timerService.remainingSeconds / phase.durationSeconds);

          return LatenteListView(
            children: [
              LatenteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.softBlue,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      TimeFormatter.minutesSeconds(
                        _timerService.remainingSeconds,
                      ),
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0).toDouble(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.water_drop_outlined),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_timerService.agitationMessage)),
                      ],
                    ),
                  ],
                ),
              ),
              _TimerSettingsCard(
                enabled: !_timerService.isRunning && !_timerService.isComplete,
                stopController: _stopController,
                fixerController: _fixerController,
                washController: _washController,
                wettingController: _wettingController,
                initialAgitationController: _initialAgitationController,
                agitationIntervalController: _agitationIntervalController,
                agitationDurationController: _agitationDurationController,
                tankController: _tankController,
                onChanged: _rebuildTimerIfIdle,
              ),
              LatenteCard(
                child: Column(
                  children: [
                    InfoRow(label: 'Pellicola', value: widget.film.displayName),
                    InfoRow(label: 'Formato', value: widget.filmFormat.label),
                    InfoRow(label: 'EI', value: '${widget.exposedIso}'),
                    InfoRow(label: 'Rivelatore', value: widget.developer.name),
                    InfoRow(label: 'Diluizione', value: widget.dilution),
                    InfoRow(label: 'Volume', value: '${widget.volumeMl} ml'),
                    InfoRow(
                      label: 'Temperatura',
                      value: '${widget.temperature.toStringAsFixed(1)} C',
                    ),
                    InfoRow(
                      label: 'Agitazione',
                      value: widget.agitationMethod.label,
                    ),
                    InfoRow(
                      label: 'Rullino stock',
                      value: '${widget.stockRollNumber}',
                    ),
                    InfoRow(
                      label: 'Tempo sviluppo',
                      value: TimeFormatter.minutesSeconds(
                        widget.calculation.finalTimeSeconds,
                      ),
                    ),
                  ],
                ),
              ),
              LatenteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fasi',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (var index = 0;
                        index < _timerService.phases.length;
                        index++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              index == _timerService.currentPhaseIndex
                                  ? AppTheme.softBlue
                                  : AppTheme.deepBlue,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index == _timerService.currentPhaseIndex
                                  ? AppTheme.inkBlack
                                  : AppTheme.silver,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(_timerService.phases[index].name),
                        trailing: Text(
                          TimeFormatter.minutesSeconds(
                            _timerService.phases[index].durationSeconds,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!_timerService.isComplete) ...[
                FilledButton.icon(
                  onPressed: _timerService.isRunning
                      ? _timerService.pause
                      : _timerService.resume,
                  icon: Icon(
                    _timerService.isRunning
                        ? Icons.pause_outlined
                        : Icons.play_arrow_outlined,
                  ),
                  label: Text(_timerService.isRunning ? 'Pausa' : 'Avvia'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _finishAndSave,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Termina'),
                ),
              ] else
                FilledButton.icon(
                  onPressed: _saved ? null : _finishAndSave,
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Salva nel diario'),
                ),
            ],
          );
        },
      ),
    );
  }

  ProcessingTimerService _buildTimerService() {
    return ProcessingTimerService.darkroom(
      developmentSeconds: widget.calculation.finalTimeSeconds,
      stopSeconds: _secondsFrom(_stopController, 30),
      fixerSeconds: _secondsFrom(_fixerController, 300),
      washSeconds: _secondsFrom(_washController, 600),
      wettingAgentSeconds: _secondsFrom(_wettingController, 60),
      initialAgitationSeconds: _secondsFrom(_initialAgitationController, 30),
      agitationIntervalSeconds: _secondsFrom(_agitationIntervalController, 60),
      agitationDurationSeconds: _secondsFrom(_agitationDurationController, 10),
    );
  }

  void _rebuildTimerIfIdle() {
    if (_timerService.isRunning || _timerService.isComplete) {
      return;
    }
    _timerService.dispose();
    setState(() => _timerService = _buildTimerService());
  }

  int _secondsFrom(TextEditingController controller, int fallback) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  Future<void> _finishAndSave() async {
    if (_saved) {
      return;
    }
    _timerService.stop();
    final session = await _buildSessionFromDialog();
    if (session == null || !mounted) {
      return;
    }

    await LatenteScope.of(context).addSession(session);
    _saved = true;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<DevelopmentSession?> _buildSessionFromDialog() {
    final notesController = TextEditingController();
    var rating = ResultRating.good;

    return showDialog<DevelopmentSession>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Salva nel diario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tankController,
                      decoration: const InputDecoration(labelText: 'Tank'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ResultRating>(
                      initialValue: rating,
                      decoration: const InputDecoration(
                        labelText: 'Risultato soggettivo',
                      ),
                      items: ResultRating.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => rating = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Note'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      DevelopmentSession(
                        id: _newId('session'),
                        date: DateTime.now(),
                        filmId: widget.film.id,
                        filmName: widget.film.displayName,
                        exposedIso: widget.exposedIso,
                        developerId: widget.developer.id,
                        developerName: widget.developer.name,
                        dilution: widget.dilution,
                        volumeMl: widget.volumeMl,
                        temperature: widget.temperature,
                        chemicalUses: widget.chemicalUses,
                        agitationMethod: widget.agitationMethod,
                        tank: _tankController.text.trim(),
                        filmFormat: widget.filmFormat,
                        stockRollNumber: widget.stockRollNumber,
                        finalTimeSeconds: widget.calculation.finalTimeSeconds,
                        resultNotes: notesController.text.trim(),
                        rating: rating,
                        referenceImagePath: null,
                      ),
                    );
                  },
                  child: const Text('Salva'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(notesController.dispose);
  }

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}

class _TimerSettingsCard extends StatelessWidget {
  const _TimerSettingsCard({
    required this.enabled,
    required this.stopController,
    required this.fixerController,
    required this.washController,
    required this.wettingController,
    required this.initialAgitationController,
    required this.agitationIntervalController,
    required this.agitationDurationController,
    required this.tankController,
    required this.onChanged,
  });

  final bool enabled;
  final TextEditingController stopController;
  final TextEditingController fixerController;
  final TextEditingController washController;
  final TextEditingController wettingController;
  final TextEditingController initialAgitationController;
  final TextEditingController agitationIntervalController;
  final TextEditingController agitationDurationController;
  final TextEditingController tankController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return LatenteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Impostazioni timer',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: tankController,
            enabled: enabled,
            decoration: const InputDecoration(labelText: 'Tank'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SmallSecondsField(
                label: 'Stop',
                controller: stopController,
                enabled: enabled,
                onChanged: onChanged,
              ),
              const SizedBox(width: 8),
              _SmallSecondsField(
                label: 'Fix',
                controller: fixerController,
                enabled: enabled,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SmallSecondsField(
                label: 'Wash',
                controller: washController,
                enabled: enabled,
                onChanged: onChanged,
              ),
              const SizedBox(width: 8),
              _SmallSecondsField(
                label: 'Wetting',
                controller: wettingController,
                enabled: enabled,
                onChanged: onChanged,
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              _SmallSecondsField(
                label: 'Agit. iniz.',
                controller: initialAgitationController,
                enabled: enabled,
                onChanged: onChanged,
              ),
              const SizedBox(width: 8),
              _SmallSecondsField(
                label: 'Intervallo',
                controller: agitationIntervalController,
                enabled: enabled,
                onChanged: onChanged,
              ),
              const SizedBox(width: 8),
              _SmallSecondsField(
                label: 'Durata',
                controller: agitationDurationController,
                enabled: enabled,
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallSecondsField extends StatelessWidget {
  const _SmallSecondsField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(labelText: '$label s'),
        keyboardType: TextInputType.number,
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
