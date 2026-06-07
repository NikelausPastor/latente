import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_data.dart';
import '../models/development_recipe.dart';
import '../services/app_state.dart';
import '../services/file_import_service.dart';
import '../services/time_formatter.dart';
import '../widgets/latente_card.dart';
import '../widgets/latente_list_view.dart';
import '../widgets/section_title.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _jsonController = TextEditingController();
  final _fileImportService = FileImportService();
  bool _initialized = false;
  bool _showAdvancedJson = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _jsonController.text = LatenteScope.of(context).exportJson();
    _initialized = true;
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: LatenteListView(
        children: [
          const SectionTitle(
            title: 'Dati e backup',
            subtitle:
                'Importa un file tecnico JSON o crea una copia manuale dei dati locali.',
          ),
          LatenteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Archivio locale',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Prima di salvare un file importato Latente mostra una lettura del contenuto e chiede conferma.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadTechnicalFile,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Carica file tecnico'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _copyCurrentBackup,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copia backup JSON'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _showAdvancedJson = !_showAdvancedJson);
                  },
                  icon: Icon(
                    _showAdvancedJson
                        ? Icons.expand_less_outlined
                        : Icons.data_object_outlined,
                  ),
                  label: Text(
                    _showAdvancedJson
                        ? 'Nascondi JSON manuale'
                        : 'Import manuale JSON',
                  ),
                ),
                if (_showAdvancedJson) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _jsonController,
                    minLines: 8,
                    maxLines: 16,
                    decoration: const InputDecoration(
                      labelText: 'JSON manuale',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refreshJson,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Rigenera dal dispositivo'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _importJsonFromText,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Leggi e importa'),
                  ),
                ],
              ],
            ),
          ),
          LatenteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CSV', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Struttura preparata per una futura esportazione CSV. In questa MVP il formato operativo resta JSON.',
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _resetSamples,
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Ripristina dati di esempio'),
          ),
        ],
      ),
    );
  }

  void _refreshJson() {
    setState(() {
      _jsonController.text = LatenteScope.of(context).exportJson();
    });
  }

  Future<void> _copyCurrentBackup() async {
    final json = LatenteScope.of(context).exportJson();
    setState(() => _jsonController.text = json);
    await Clipboard.setData(ClipboardData(text: json));
    _showSnack('Backup JSON copiato negli appunti.');
  }

  Future<void> _loadTechnicalFile() async {
    try {
      final rawJson = await _fileImportService.pickTechnicalTextFile();
      if (!mounted || rawJson == null || rawJson.trim().isEmpty) {
        return;
      }
      setState(() => _jsonController.text = rawJson);
      await _previewAndImport(rawJson, sourceLabel: 'file tecnico');
    } on MissingPluginException {
      _showSnack('Caricamento file non disponibile su questa build.');
    } on PlatformException catch (error) {
      _showSnack(error.message ?? 'Impossibile leggere il file selezionato.');
    } on FileImportException catch (error) {
      _showSnack(error.message);
    }
  }

  Future<void> _importJsonFromText() async {
    await _previewAndImport(_jsonController.text, sourceLabel: 'testo JSON');
  }

  Future<void> _previewAndImport(
    String rawJson, {
    required String sourceLabel,
  }) async {
    final appState = LatenteScope.of(context);
    late final AppData previewData;

    try {
      previewData = appState.previewJson(rawJson);
    } catch (_) {
      _showSnack('File tecnico non valido: serve un JSON compatibile.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Controllo importazione'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Origine: $sourceLabel'),
                const SizedBox(height: 8),
                const Text(
                  'Se confermi, l\'archivio locale attuale viene sostituito.',
                ),
                const SizedBox(height: 14),
                Text(
                  _buildPreview(previewData),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salva importazione'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await appState.importJson(rawJson);
    setState(() => _jsonController.text = appState.exportJson());
    _showSnack('Archivio importato correttamente.');
  }

  String _buildPreview(AppData data) {
    final lines = <String>[
      'Pellicole: ${data.films.length}',
      ..._limited(
        data.films
            .map((film) => '${film.displayName} / ISO ${film.nominalIso}'),
      ),
      '',
      'Chimici: ${data.chemicals.length}',
      ..._limited(data.chemicals.map((chemical) => chemical.name)),
      '',
      'Ricette sviluppo: ${data.recipes.length}',
      ..._limited(data.recipes.map((recipe) => _recipePreview(data, recipe))),
      '',
      'Storico lavorazioni: ${data.sessions.length}',
      ..._limited(
        data.sessions.map(
          (session) =>
              '${session.filmName} / ${session.developerName} / ${TimeFormatter.minutesSeconds(session.finalTimeSeconds)}',
        ),
      ),
    ];

    if (data.films.isEmpty &&
        data.chemicals.isEmpty &&
        data.recipes.isEmpty &&
        data.sessions.isEmpty) {
      lines.add('');
      lines.add('Nessun dato tecnico trovato nel file.');
    }

    return lines.join('\n');
  }

  Iterable<String> _limited(Iterable<String> values) {
    final list = values.where((value) => value.trim().isNotEmpty).toList();
    if (list.isEmpty) {
      return const ['- nessun elemento'];
    }
    final visible = list.take(6).map((value) => '- $value').toList();
    final remaining = list.length - visible.length;
    if (remaining > 0) {
      visible.add('- altri $remaining elementi...');
    }
    return visible;
  }

  String _recipePreview(AppData data, DevelopmentRecipe recipe) {
    final filmName = _firstMatch(
      data.films
          .where((film) => film.id == recipe.filmId)
          .map((film) => film.displayName),
    );
    final developerName = _firstMatch(
      data.chemicals
          .where((chemical) => chemical.id == recipe.developerId)
          .map((chemical) => chemical.name),
    );

    return '${filmName ?? 'Pellicola'} / ${developerName ?? 'Rivelatore'} / ${recipe.dilution} / ${TimeFormatter.minutesSeconds(recipe.baseTimeSeconds)}';
  }

  String? _firstMatch(Iterable<String> values) {
    for (final value in values) {
      return value;
    }
    return null;
  }

  Future<void> _resetSamples() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ripristinare esempi?'),
        content: const Text(
          'I dati attuali verranno sostituiti dai dati fittizi iniziali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await LatenteScope.of(context).resetToSampleData();
      _refreshJson();
      _showSnack('Dati di esempio ripristinati.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
