import 'dart:async';

import 'package:flutter/foundation.dart';

class ProcessingPhase {
  const ProcessingPhase({
    required this.name,
    required this.durationSeconds,
  });

  final String name;
  final int durationSeconds;
}

class ProcessingTimerService extends ChangeNotifier {
  ProcessingTimerService({
    required List<ProcessingPhase> phases,
    this.initialAgitationSeconds = 30,
    this.agitationIntervalSeconds = 60,
    this.agitationDurationSeconds = 10,
  })  : _phases = phases,
        _remainingSeconds = phases.isEmpty ? 0 : phases.first.durationSeconds;

  factory ProcessingTimerService.darkroom({
    required int developmentSeconds,
    int stopSeconds = 30,
    int fixerSeconds = 300,
    int washSeconds = 600,
    int wettingAgentSeconds = 60,
    int initialAgitationSeconds = 30,
    int agitationIntervalSeconds = 60,
    int agitationDurationSeconds = 10,
  }) {
    final phases = <ProcessingPhase>[
      ProcessingPhase(name: 'Sviluppo', durationSeconds: developmentSeconds),
    ];
    if (stopSeconds > 0) {
      phases
          .add(ProcessingPhase(name: 'Arresto', durationSeconds: stopSeconds));
    }
    if (fixerSeconds > 0) {
      phases.add(
        ProcessingPhase(name: 'Fissaggio', durationSeconds: fixerSeconds),
      );
    }
    if (washSeconds > 0) {
      phases
          .add(ProcessingPhase(name: 'Lavaggio', durationSeconds: washSeconds));
    }
    if (wettingAgentSeconds > 0) {
      phases.add(
        ProcessingPhase(
            name: 'Imbibente', durationSeconds: wettingAgentSeconds),
      );
    }

    return ProcessingTimerService(
      phases: phases,
      initialAgitationSeconds: initialAgitationSeconds,
      agitationIntervalSeconds: agitationIntervalSeconds,
      agitationDurationSeconds: agitationDurationSeconds,
    );
  }

  final List<ProcessingPhase> _phases;
  final int initialAgitationSeconds;
  final int agitationIntervalSeconds;
  final int agitationDurationSeconds;
  Timer? _timer;
  int _currentPhaseIndex = 0;
  int _remainingSeconds;
  bool _isRunning = false;
  bool _isComplete = false;

  List<ProcessingPhase> get phases => _phases;
  ProcessingPhase get currentPhase => _phases[_currentPhaseIndex];
  int get currentPhaseIndex => _currentPhaseIndex;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isComplete => _isComplete;

  String get agitationMessage {
    if (currentPhase.name != 'Sviluppo') {
      return 'Nessuna agitazione prevista in questa fase.';
    }

    final elapsed = currentPhase.durationSeconds - _remainingSeconds;
    if (elapsed < initialAgitationSeconds) {
      return 'Agitazione iniziale: $initialAgitationSeconds secondi.';
    }

    if (agitationIntervalSeconds <= 0 || agitationDurationSeconds <= 0) {
      return 'Riposo: agitazione periodica disattivata.';
    }

    final secondsInCycle = elapsed % agitationIntervalSeconds;
    if (secondsInCycle < agitationDurationSeconds) {
      return 'Agitazione: $agitationDurationSeconds secondi.';
    }

    return 'Riposo: mantenere il ritmo previsto.';
  }

  void start() {
    if (_isRunning || _isComplete) {
      return;
    }
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resume() {
    start();
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _isComplete = true;
    notifyListeners();
  }

  void _tick() {
    if (_remainingSeconds > 0) {
      _remainingSeconds -= 1;
      notifyListeners();
      return;
    }

    if (_currentPhaseIndex < _phases.length - 1) {
      _currentPhaseIndex += 1;
      _remainingSeconds = currentPhase.durationSeconds;
      notifyListeners();
      return;
    }

    stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
