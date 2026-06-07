import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/film.dart';
import '../services/app_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_row.dart';
import '../widgets/latente_card.dart';
import '../widgets/latente_list_view.dart';
import '../widgets/section_title.dart';

class FilmArchiveScreen extends StatelessWidget {
  const FilmArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = LatenteScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Archivio pellicole')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Pellicola'),
      ),
      body: appState.films.isEmpty
          ? const SafeArea(
              child: EmptyState(
                title: 'Nessuna pellicola',
                message: 'Aggiungi la prima scheda tecnica.',
              ),
            )
          : LatenteListView(
              children: [
                const SectionTitle(
                  title: 'Pellicole',
                  subtitle: 'Archivio tecnico modificabile.',
                ),
                for (final film in appState.films)
                  LatenteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                film.displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Modifica',
                              onPressed: () => _openForm(context, film),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Elimina',
                              onPressed: () => _delete(context, film),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const Divider(),
                        InfoRow(
                            label: 'ISO nominale', value: '${film.nominalIso}'),
                        InfoRow(label: 'Formato', value: film.format.label),
                        InfoRow(
                          label: 'Supporto tiratura',
                          value: film.supportsPushPull ? 'Sì' : 'No',
                        ),
                        if (film.recommendedPushPullIso.isNotEmpty)
                          InfoRow(
                            label: 'ISO push/pull',
                            value: film.recommendedPushPullIso.join(', '),
                          ),
                        if (film.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(film.notes),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  void _openForm(BuildContext context, [Film? film]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FilmFormScreen(film: film)),
    );
  }

  Future<void> _delete(BuildContext context, Film film) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare pellicola?'),
        content: Text(
          'Eliminando ${film.displayName} verranno rimosse anche le ricette collegate.',
        ),
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
      await LatenteScope.of(context).deleteFilm(film.id);
    }
  }
}

class FilmFormScreen extends StatefulWidget {
  const FilmFormScreen({this.film, super.key});

  final Film? film;

  @override
  State<FilmFormScreen> createState() => _FilmFormScreenState();
}

class _FilmFormScreenState extends State<FilmFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _nameController;
  late final TextEditingController _isoController;
  late final TextEditingController _notesController;
  late final TextEditingController _pushIsoController;
  late FilmFormat _format;
  late bool _supportsPushPull;

  @override
  void initState() {
    super.initState();
    final film = widget.film;
    _brandController = TextEditingController(text: film?.brand ?? '');
    _nameController = TextEditingController(text: film?.name ?? '');
    _isoController =
        TextEditingController(text: (film?.nominalIso ?? 400).toString());
    _notesController = TextEditingController(text: film?.notes ?? '');
    _pushIsoController = TextEditingController(
      text: film?.recommendedPushPullIso.join(', ') ?? '',
    );
    _format = film?.format ?? FilmFormat.thirtyFiveMm;
    _supportsPushPull = film?.supportsPushPull ?? true;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _nameController.dispose();
    _isoController.dispose();
    _notesController.dispose();
    _pushIsoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.film != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica pellicola' : 'Nuova pellicola'),
      ),
      body: Form(
        key: _formKey,
        child: LatenteListView(
          children: [
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Marca'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isoController,
              decoration: const InputDecoration(labelText: 'ISO nominale'),
              keyboardType: TextInputType.number,
              validator: _positiveInteger,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FilmFormat>(
              initialValue: _format,
              decoration: const InputDecoration(labelText: 'Formato'),
              items: FilmFormat.values
                  .map(
                    (format) => DropdownMenuItem(
                      value: format,
                      child: Text(format.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _format = value);
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Supporto tiratura'),
              subtitle: const Text('Push/pull consentito per questa pellicola'),
              value: _supportsPushPull,
              onChanged: (value) => setState(() => _supportsPushPull = value),
            ),
            TextFormField(
              controller: _pushIsoController,
              decoration: const InputDecoration(
                labelText: 'ISO consigliati per push/pull',
                hintText: 'Esempio: 200, 400, 800, 1600',
              ),
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
              label: const Text('Salva pellicola'),
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

    final film = Film(
      id: widget.film?.id ?? _newId('film'),
      brand: _brandController.text.trim(),
      name: _nameController.text.trim(),
      nominalIso: int.parse(_isoController.text.trim()),
      format: _format,
      notes: _notesController.text.trim(),
      supportsPushPull: _supportsPushPull,
      recommendedPushPullIso: _parseIsoList(_pushIsoController.text),
    );

    await LatenteScope.of(context).upsertFilm(film);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<int> _parseIsoList(String value) {
    return value
        .split(',')
        .map((item) => int.tryParse(item.trim()))
        .whereType<int>()
        .toList();
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

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
