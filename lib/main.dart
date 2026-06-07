import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_state.dart';
import 'services/local_data_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LatenteApp());
}

class LatenteApp extends StatefulWidget {
  const LatenteApp({super.key});

  @override
  State<LatenteApp> createState() => _LatenteAppState();
}

class _LatenteAppState extends State<LatenteApp> {
  late final LatenteAppState appState;

  @override
  void initState() {
    super.initState();
    appState = LatenteAppState(LocalDataService())..load();
  }

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LatenteScope(
      notifier: appState,
      child: MaterialApp(
        title: 'Latente',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const HomeScreen(),
      ),
    );
  }
}
