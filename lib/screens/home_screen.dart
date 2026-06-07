import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/latente_card.dart';
import '../widgets/latente_list_view.dart';
import 'chemical_archive_screen.dart';
import 'film_archive_screen.dart';
import 'history_screen.dart';
import 'import_export_screen.dart';
import 'new_development_screen.dart';
import 'recipe_archive_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = LatenteScope.of(context);

    return Scaffold(
      body: appState.isLoading
          ? const SafeArea(child: Center(child: CircularProgressIndicator()))
          : LatenteListView(
              topSafeArea: true,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Text(
                  'Latente',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.silver,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Calcolatore e timer per sviluppo analogico',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.softBlue,
                      ),
                ),
                const SizedBox(height: 20),
                const LatenteCard(
                  child: Text(SampleData.sampleNotice),
                ),
                const SizedBox(height: 8),
                _HomeAction(
                  icon: Icons.science_outlined,
                  label: 'Nuovo sviluppo',
                  subtitle: 'Calcola il tempo finale e avvia il timer',
                  onTap: () => _open(context, const NewDevelopmentScreen()),
                ),
                _HomeAction(
                  icon: Icons.camera_roll_outlined,
                  label: 'Archivio pellicole',
                  subtitle: '${appState.films.length} schede pellicola',
                  onTap: () => _open(context, const FilmArchiveScreen()),
                ),
                _HomeAction(
                  icon: Icons.opacity_outlined,
                  label: 'Archivio chimici',
                  subtitle: '${appState.chemicals.length} chimici salvati',
                  onTap: () => _open(context, const ChemicalArchiveScreen()),
                ),
                _HomeAction(
                  icon: Icons.receipt_long_outlined,
                  label: 'Ricette sviluppo',
                  subtitle: '${appState.recipes.length} ricette tecniche',
                  onTap: () => _open(context, const RecipeArchiveScreen()),
                ),
                _HomeAction(
                  icon: Icons.history_outlined,
                  label: 'Diario sviluppo',
                  subtitle: '${appState.sessions.length} sessioni salvate',
                  onTap: () => _open(context, const HistoryScreen()),
                ),
                _HomeAction(
                  icon: Icons.settings_outlined,
                  label: 'Impostazioni',
                  subtitle: 'Backup, import file tecnico e dati di esempio',
                  onTap: () => _open(context, const SettingsScreen()),
                ),
              ],
            ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LatenteCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.softBlue),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
