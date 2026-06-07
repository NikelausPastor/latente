import 'package:flutter/widgets.dart';

import '../data/sample_data.dart';
import '../models/app_data.dart';
import '../models/chemical.dart';
import '../models/development_recipe.dart';
import '../models/development_session.dart';
import '../models/film.dart';
import 'local_data_service.dart';

class LatenteAppState extends ChangeNotifier {
  LatenteAppState(this._localDataService);

  final LocalDataService _localDataService;

  AppData _data = AppData.empty();
  bool _isLoading = true;
  String? _message;

  AppData get data => _data;
  List<Film> get films => _data.films;
  List<Chemical> get chemicals => _data.chemicals;
  List<DevelopmentRecipe> get recipes => _data.recipes;
  List<DevelopmentSession> get sessions => _data.sessions;
  bool get isLoading => _isLoading;
  String? get message => _message;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _data = await _localDataService.load();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> resetToSampleData() async {
    _data = SampleData.create();
    _message = 'Dati di esempio ripristinati.';
    await _persist();
  }

  Future<void> importJson(String rawJson) async {
    _data = SampleData.ensureReferenceData(_localDataService.decode(rawJson));
    _message = 'Archivio importato correttamente.';
    await _persist();
  }

  AppData previewJson(String rawJson) {
    return _localDataService.decode(rawJson);
  }

  String exportJson() {
    return _localDataService.encode(_data);
  }

  Future<void> upsertFilm(Film film) async {
    final items = [..._data.films];
    final index = items.indexWhere((item) => item.id == film.id);
    if (index >= 0) {
      items[index] = film;
    } else {
      items.add(film);
    }
    _data = _data.copyWith(films: items);
    _message = 'Pellicola salvata.';
    await _persist();
  }

  Future<void> deleteFilm(String id) async {
    _data = _data.copyWith(
      films: _data.films.where((item) => item.id != id).toList(),
      recipes: _data.recipes.where((item) => item.filmId != id).toList(),
    );
    _message = 'Pellicola eliminata.';
    await _persist();
  }

  Future<void> upsertChemical(Chemical chemical) async {
    final items = [..._data.chemicals];
    final index = items.indexWhere((item) => item.id == chemical.id);
    if (index >= 0) {
      items[index] = chemical;
    } else {
      items.add(chemical);
    }
    _data = _data.copyWith(chemicals: items);
    _message = 'Chimico salvato.';
    await _persist();
  }

  Future<void> deleteChemical(String id) async {
    _data = _data.copyWith(
      chemicals: _data.chemicals.where((item) => item.id != id).toList(),
      recipes: _data.recipes.where((item) => item.developerId != id).toList(),
    );
    _message = 'Chimico eliminato.';
    await _persist();
  }

  Future<void> upsertRecipe(DevelopmentRecipe recipe) async {
    final items = [..._data.recipes];
    final index = items.indexWhere((item) => item.id == recipe.id);
    if (index >= 0) {
      items[index] = recipe;
    } else {
      items.add(recipe);
    }
    _data = _data.copyWith(recipes: items);
    _message = 'Ricetta salvata.';
    await _persist();
  }

  Future<void> deleteRecipe(String id) async {
    _data = _data.copyWith(
      recipes: _data.recipes.where((item) => item.id != id).toList(),
    );
    _message = 'Ricetta eliminata.';
    await _persist();
  }

  Future<void> addSession(DevelopmentSession session) async {
    _data = _data.copyWith(sessions: [session, ..._data.sessions]);
    _message = 'Lavorazione salvata nello storico.';
    await _persist();
  }

  Future<void> updateSession(DevelopmentSession session) async {
    final items = [..._data.sessions];
    final index = items.indexWhere((item) => item.id == session.id);
    if (index >= 0) {
      items[index] = session;
      _data = _data.copyWith(sessions: items);
      _message = 'Scheda storico aggiornata.';
      await _persist();
    }
  }

  Future<void> deleteSession(String id) async {
    _data = _data.copyWith(
      sessions: _data.sessions.where((item) => item.id != id).toList(),
    );
    _message = 'Scheda storico eliminata.';
    await _persist();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _localDataService.save(_data);
    notifyListeners();
  }
}

class LatenteScope extends InheritedNotifier<LatenteAppState> {
  const LatenteScope({
    required LatenteAppState super.notifier,
    required super.child,
    super.key,
  });

  static LatenteAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LatenteScope>();
    assert(scope != null, 'LatenteScope non trovato nel widget tree.');
    return scope!.notifier!;
  }
}
