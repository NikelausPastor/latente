import 'package:flutter/material.dart';

import '../models/development_recipe.dart';
import '../models/development_session.dart';
import '../models/enums.dart';
import '../models/film.dart';
import '../services/app_state.dart';
import '../services/time_formatter.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_row.dart';
import '../widgets/latente_card.dart';
import '../widgets/latente_list_view.dart';
import '../widgets/section_title.dart';
import 'new_development_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = LatenteScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Diario sviluppo')),
      body: appState.sessions.isEmpty
          ? const SafeArea(
              child: EmptyState(
                title: 'Diario vuoto',
                message: 'Le lavorazioni salvate compariranno qui.',
              ),
            )
          : LatenteListView(
              children: [
                const SectionTitle(
                  title: 'Development log',
                  subtitle: 'Schede tecniche create al termine del timer.',
                ),
                for (final session in appState.sessions)
                  LatenteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.filmName,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(session.date),
                                    style: const TextStyle(
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Riusa dati',
                              onPressed: () => _reuse(context, session),
                              icon: const Icon(Icons.replay_outlined),
                            ),
                            IconButton(
                              tooltip: 'Preset personale',
                              onPressed: () => _saveAsPreset(context, session),
                              icon: const Icon(Icons.bookmark_add_outlined),
                            ),
                            IconButton(
                              tooltip: 'Modifica note',
                              onPressed: () => _edit(context, session),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Elimina',
                              onPressed: () => _delete(context, session),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const Divider(),
                        InfoRow(
                            label: 'Formato', value: session.filmFormat.label),
                        InfoRow(label: 'EI', value: '${session.exposedIso}'),
                        InfoRow(
                            label: 'Rivelatore', value: session.developerName),
                        InfoRow(label: 'Diluizione', value: session.dilution),
                        InfoRow(
                            label: 'Volume', value: '${session.volumeMl} ml'),
                        InfoRow(
                          label: 'Temperatura',
                          value: '${session.temperature.toStringAsFixed(1)} C',
                        ),
                        InfoRow(
                          label: 'Agitazione',
                          value: session.agitationMethod.label,
                        ),
                        InfoRow(
                          label: 'Tank',
                          value: session.tank.trim().isEmpty
                              ? 'Non indicata'
                              : session.tank,
                        ),
                        InfoRow(
                          label: 'Rullino stock',
                          value: '${session.stockRollNumber}',
                        ),
                        InfoRow(
                          label: 'Tempo finale',
                          value: TimeFormatter.minutesSeconds(
                              session.finalTimeSeconds),
                        ),
                        InfoRow(
                          label: 'Risultato',
                          value: session.rating.label,
                        ),
                        if (session.resultNotes.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(session.resultNotes),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  void _reuse(BuildContext context, DevelopmentSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewDevelopmentScreen(initialSession: session),
      ),
    );
  }

  Future<void> _saveAsPreset(
    BuildContext context,
    DevelopmentSession session,
  ) async {
    final appState = LatenteScope.of(context);
    final film = _findFilm(appState.films, session);
    final recipe = DevelopmentRecipe(
      id: 'recipe_user_${session.id}',
      filmId: session.filmId,
      filmBrand: film?.brand ?? '',
      filmName: film?.name ?? session.filmName,
      nominalIso: film?.nominalIso ?? session.exposedIso,
      exposedIso: session.exposedIso,
      ei: session.exposedIso,
      developerId: session.developerId,
      developerName: session.developerName,
      dilution: session.dilution,
      baseTemperatureC: session.temperature,
      baseTimeSeconds: session.finalTimeSeconds,
      agitation: session.agitationMethod.label,
      sourceType: SourceType.user,
      sourceName: 'Development log personale',
      sourceDate: _dateOnly(session.date),
      notes: session.resultNotes,
      confidence: ConfidenceLevel.medium,
    );
    await appState.upsertRecipe(recipe);
  }

  Future<void> _edit(BuildContext context, DevelopmentSession session) async {
    final notesController = TextEditingController(text: session.resultNotes);
    var rating = session.rating;

    final updated = await showDialog<DevelopmentSession>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifica scheda'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<ResultRating>(
                      initialValue: rating,
                      decoration: const InputDecoration(labelText: 'Risultato'),
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
                      session.copyWith(
                        rating: rating,
                        resultNotes: notesController.text.trim(),
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

    if (updated != null && context.mounted) {
      await LatenteScope.of(context).updateSession(updated);
    }
  }

  Future<void> _delete(BuildContext context, DevelopmentSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare scheda?'),
        content: const Text('La lavorazione verra rimossa dal diario.'),
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
      await LatenteScope.of(context).deleteSession(session.id);
    }
  }

  static Film? _findFilm(List<Film> films, DevelopmentSession session) {
    for (final film in films) {
      if (film.id == session.filmId || film.displayName == session.filmName) {
        return film;
      }
    }
    return null;
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  static String _dateOnly(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}
