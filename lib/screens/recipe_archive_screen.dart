import 'package:flutter/material.dart';

import '../models/chemical.dart';
import '../models/development_recipe.dart';
import '../models/enums.dart';
import '../models/film.dart';
import '../services/app_state.dart';
import '../services/time_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_row.dart';
import '../widgets/latente_card.dart';
import '../widgets/latente_list_view.dart';
import '../widgets/section_title.dart';

class RecipeArchiveScreen extends StatelessWidget {
  const RecipeArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = LatenteScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ricette sviluppo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: appState.films.isEmpty || _developers(appState).isEmpty
            ? null
            : () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Ricetta'),
      ),
      body: appState.recipes.isEmpty
          ? const SafeArea(
              child: EmptyState(
                title: 'Nessuna ricetta',
                message:
                    'Aggiungi almeno una pellicola e un rivelatore, poi salva una ricetta.',
              ),
            )
          : LatenteListView(
              children: [
                const SectionTitle(
                  title: 'Ricette',
                  subtitle: 'Tempi base, fonti e affidabilita dichiarata.',
                ),
                for (final recipe in appState.recipes)
                  LatenteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_filmName(appState.films, recipe.filmId)} / ${_chemicalName(appState.chemicals, recipe.developerId)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Modifica',
                              onPressed: () => _openForm(context, recipe),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Elimina',
                              onPressed: () => _delete(context, recipe),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const Divider(),
                        InfoRow(
                          label: 'ISO nominale',
                          value: '${recipe.nominalIso}',
                        ),
                        InfoRow(label: 'EI', value: '${recipe.ei}'),
                        InfoRow(label: 'Diluizione', value: recipe.dilution),
                        InfoRow(
                          label: 'Temperatura rif.',
                          value:
                              '${recipe.referenceTemperature.toStringAsFixed(1)} C',
                        ),
                        InfoRow(
                          label: 'Tempo base',
                          value: TimeFormatter.minutesSeconds(
                              recipe.baseTimeSeconds),
                        ),
                        InfoRow(label: 'Agitazione', value: recipe.agitation),
                        InfoRow(
                          label: 'Tipo fonte',
                          value: recipe.sourceType.label,
                        ),
                        if (recipe.sourceName.trim().isNotEmpty)
                          InfoRow(label: 'Fonte', value: recipe.sourceName),
                        if (recipe.sourceDate != null &&
                            recipe.sourceDate!.trim().isNotEmpty)
                          InfoRow(
                              label: 'Data fonte', value: recipe.sourceDate!),
                        InfoRow(
                          label: 'Affidabilita',
                          value: recipe.confidence.label,
                        ),
                        if (recipe.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(recipe.notes),
                        ],
                      ],
                    ),
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

  static String _filmName(List<Film> films, String id) {
    return films
        .firstWhere(
          (film) => film.id == id,
          orElse: () => const Film(
            id: '',
            brand: 'Pellicola',
            name: 'non trovata',
            nominalIso: 0,
            format: FilmFormat.other,
            notes: '',
            supportsPushPull: false,
            recommendedPushPullIso: [],
          ),
        )
        .displayName;
  }

  static String _chemicalName(List<Chemical> chemicals, String id) {
    return chemicals
        .firstWhere(
          (chemical) => chemical.id == id,
          orElse: () => const Chemical(
            id: '',
            name: 'Rivelatore non trovato',
            type: ChemicalType.developer,
            dilutions: [],
            oneShot: true,
            maxUses: null,
            wearRule: WearRule.none,
            wearIncrement: 0,
          ),
        )
        .name;
  }

  void _openForm(BuildContext context, [DevelopmentRecipe? recipe]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecipeFormScreen(recipe: recipe)),
    );
  }

  Future<void> _delete(BuildContext context, DevelopmentRecipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare ricetta?'),
        content: const Text('La ricetta verra rimossa dall archivio.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await LatenteScope.of(context).deleteRecipe(recipe.id);
    }
  }
}

class RecipeFormScreen extends StatefulWidget {
  const RecipeFormScreen({this.recipe, super.key});

  final DevelopmentRecipe? recipe;

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nominalIsoController = TextEditingController();
  final _exposedIsoController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _agitationController = TextEditingController();
  final _sourceNameController = TextEditingController();
  final _sourceDateController = TextEditingController();
  final _notesController = TextEditingController();

  bool _initialized = false;
  late String _filmId;
  late String _developerId;
  late String _dilution;
  SourceType _sourceType = SourceType.user;
  ConfidenceLevel _confidence = ConfidenceLevel.medium;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final appState = LatenteScope.of(context);
    final developers = appState.chemicals
        .where((chemical) => chemical.type == ChemicalType.developer)
        .toList();
    if (appState.films.isEmpty || developers.isEmpty) {
      _initialized = true;
      return;
    }

    final recipe = widget.recipe;
    final film = recipe == null
        ? appState.films.first
        : appState.films.firstWhere(
            (item) => item.id == recipe.filmId,
            orElse: () => appState.films.first,
          );
    final developer = recipe == null
        ? developers.first
        : developers.firstWhere(
            (item) => item.id == recipe.developerId,
            orElse: () => developers.first,
          );

    _filmId = recipe?.filmId ?? film.id;
    _developerId = recipe?.developerId ?? developer.id;
    _dilution = recipe?.dilution ??
        (developer.dilutions.isNotEmpty ? developer.dilutions.first : '');
    _nominalIsoController.text =
        (recipe?.nominalIso ?? film.nominalIso).toString();
    _exposedIsoController.text = (recipe?.ei ?? film.nominalIso).toString();
    _temperatureController.text =
        (recipe?.baseTemperatureC ?? 20).toStringAsFixed(1);
    _minutesController.text =
        ((recipe?.baseTimeSeconds ?? 480) ~/ 60).toString();
    _secondsController.text =
        ((recipe?.baseTimeSeconds ?? 480) % 60).toString();
    _agitationController.text =
        recipe?.agitation ?? '30 secondi iniziali, poi 10 secondi ogni minuto';
    _sourceNameController.text = recipe?.sourceName ?? '';
    _sourceDateController.text = recipe?.sourceDate ?? '';
    _sourceType = recipe?.sourceType ?? SourceType.user;
    _confidence = recipe?.confidence ?? ConfidenceLevel.medium;
    _notesController.text = recipe?.notes ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _nominalIsoController.dispose();
    _exposedIsoController.dispose();
    _temperatureController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _agitationController.dispose();
    _sourceNameController.dispose();
    _sourceDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = LatenteScope.of(context);
    final developers = appState.chemicals
        .where((chemical) => chemical.type == ChemicalType.developer)
        .toList();

    if (appState.films.isEmpty || developers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ricetta sviluppo')),
        body: const SafeArea(
          child: EmptyState(
            title: 'Archivio incompleto',
            message: 'Servono almeno una pellicola e un rivelatore.',
          ),
        ),
      );
    }

    final currentDeveloper = developers.firstWhere(
      (chemical) => chemical.id == _developerId,
      orElse: () => developers.first,
    );
    final dilutions = currentDeveloper.dilutions.isEmpty
        ? <String>[_dilution]
        : currentDeveloper.dilutions;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.recipe == null ? 'Nuova ricetta' : 'Modifica ricetta'),
      ),
      body: Form(
        key: _formKey,
        child: LatenteListView(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _filmId,
              decoration: const InputDecoration(labelText: 'Pellicola'),
              items: appState.films
                  .map(
                    (film) => DropdownMenuItem(
                      value: film.id,
                      child: Text(film.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  final film =
                      appState.films.firstWhere((item) => item.id == value);
                  setState(() {
                    _filmId = value;
                    _nominalIsoController.text = film.nominalIso.toString();
                    _exposedIsoController.text = film.nominalIso.toString();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nominalIsoController,
                    decoration:
                        const InputDecoration(labelText: 'ISO nominale'),
                    keyboardType: TextInputType.number,
                    validator: _positiveInteger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _exposedIsoController,
                    decoration: const InputDecoration(labelText: 'EI'),
                    keyboardType: TextInputType.number,
                    validator: _positiveInteger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _developerId,
              decoration: const InputDecoration(labelText: 'Rivelatore'),
              items: developers
                  .map(
                    (chemical) => DropdownMenuItem(
                      value: chemical.id,
                      child: Text(chemical.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  final developer =
                      developers.firstWhere((item) => item.id == value);
                  setState(() {
                    _developerId = value;
                    _dilution = developer.dilutions.isNotEmpty
                        ? developer.dilutions.first
                        : '';
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  dilutions.contains(_dilution) ? _dilution : dilutions.first,
              decoration: const InputDecoration(labelText: 'Diluizione'),
              items: dilutions
                  .map(
                    (dilution) => DropdownMenuItem(
                      value: dilution,
                      child: Text(dilution),
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
            TextFormField(
              controller: _temperatureController,
              decoration: const InputDecoration(
                labelText: 'Temperatura di riferimento C',
              ),
              keyboardType: TextInputType.number,
              validator: _positiveNumber,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minutesController,
                    decoration: const InputDecoration(labelText: 'Minuti'),
                    keyboardType: TextInputType.number,
                    validator: _positiveOrZero,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _secondsController,
                    decoration: const InputDecoration(labelText: 'Secondi'),
                    keyboardType: TextInputType.number,
                    validator: _seconds,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _agitationController,
              decoration:
                  const InputDecoration(labelText: 'Agitazione consigliata'),
              minLines: 2,
              maxLines: 4,
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceNameController,
              decoration: const InputDecoration(labelText: 'Nome fonte'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceDateController,
              decoration: const InputDecoration(
                labelText: 'Data fonte',
                hintText: 'Opzionale, es. 2026-06-07',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SourceType>(
              initialValue: _sourceType,
              decoration: const InputDecoration(labelText: 'Tipo fonte'),
              items: SourceType.values
                  .map(
                    (sourceType) => DropdownMenuItem(
                      value: sourceType,
                      child: Text(sourceType.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sourceType = value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ConfidenceLevel>(
              initialValue: _confidence,
              decoration: const InputDecoration(labelText: 'Affidabilita'),
              items: ConfidenceLevel.values
                  .map(
                    (confidence) => DropdownMenuItem(
                      value: confidence,
                      child: Text(confidence.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _confidence = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Note'),
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salva ricetta'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appState = LatenteScope.of(context);
    final film = appState.films.firstWhere((item) => item.id == _filmId);
    final developer =
        appState.chemicals.firstWhere((item) => item.id == _developerId);
    final minutes = int.parse(_minutesController.text.trim());
    final seconds = int.parse(_secondsController.text.trim());
    final ei = int.parse(_exposedIsoController.text.trim());
    final recipe = DevelopmentRecipe(
      id: widget.recipe?.id ?? _newId('recipe'),
      filmId: _filmId,
      filmBrand: film.brand,
      filmName: film.name,
      nominalIso: int.parse(_nominalIsoController.text.trim()),
      exposedIso: ei,
      ei: ei,
      developerId: _developerId,
      developerName: developer.name,
      dilution: _dilution,
      baseTemperatureC: double.parse(_temperatureController.text.trim()),
      baseTimeSeconds: (minutes * 60) + seconds,
      agitation: _agitationController.text.trim(),
      sourceType: _sourceType,
      sourceName: _sourceNameController.text.trim(),
      sourceDate: _sourceDateController.text.trim().isEmpty
          ? null
          : _sourceDateController.text.trim(),
      notes: _notesController.text.trim(),
      confidence: _confidence,
    );

    await appState.upsertRecipe(recipe);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obbligatorio';
    }
    return null;
  }

  String? _positiveInteger(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number <= 0) {
      return 'Inserire un numero valido';
    }
    return null;
  }

  String? _positiveNumber(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null || number <= 0) {
      return 'Inserire un numero valido';
    }
    return null;
  }

  String? _positiveOrZero(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0) {
      return 'Inserire un numero valido';
    }
    return null;
  }

  String? _seconds(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0 || number > 59) {
      return '0-59';
    }
    return null;
  }

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
