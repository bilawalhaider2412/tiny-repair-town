/// Tiny Repair Town — Flutter app entry (Stage 3).
///
/// Routing: home (Play + Parents) -> town map -> level -> celebration.
/// Lifecycle: pause on backgrounded (checkpoint saved by the active screen);
/// audio hooks never autoplay on resume (no real audio assets yet — see
/// audio.dart). Language/RTL comes from AppState; switching preserves
/// progress.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiny_repair_town/core/localization.dart';

import 'app_state.dart';
import 'app_theme.dart';
import 'audio.dart';
import 'level_repository.dart';
import 'screens/celebration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_screen.dart';
import 'screens/parents_screen.dart';
import 'screens/town_map_screen.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = LevelRepository();
  final levels = await repository.loadCatalog();
  final state = await AppState.load(
    storage: PathProviderSaveStorage(),
    levels: levels,
  );
  AudioService.instance.applySettings(
    music: state.saveStore.data.audio['music'] == true,
    effects: state.saveStore.data.audio['effects'] == true,
    narration: state.saveStore.data.audio['narration'] == true,
  );
  runApp(TinyRepairTownApp(state: state, repository: repository));
}

class TinyRepairTownApp extends StatefulWidget {
  final AppState state;
  final LevelRepository repository;

  const TinyRepairTownApp({
    super.key,
    required this.state,
    required this.repository,
  });

  @override
  State<TinyRepairTownApp> createState() => _TinyRepairTownAppState();
}

class _TinyRepairTownAppState extends State<TinyRepairTownApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Pause the active puzzle (it checkpoints) and stop audio.
      widget.state.onBackgroundPause?.call();
      AudioService.instance.pauseAll();
    } else if (state == AppLifecycleState.resumed) {
      // Never autoplay audio on resume (spec §10).
      AudioService.instance.onResumedWithoutAutoplay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.state.lang;
    return MaterialApp(
      title: tr('appTitle', lang),
      theme: TownTheme.light(),
      // Urdu => RTL via the framework's locale handling; layout mirroring
      // applies to navigation, never to authored puzzle content (spec §13).
      locale: Locale(lang),
      supportedLocales: const [Locale('en'), Locale('ur')],
      // Required for non-English locales: without these delegates the app
      // crashes with "No MaterialLocalizations found" the moment Urdu is
      // selected. They also provide the RTL Directionality for Urdu.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Larger-text accessibility setting: scales text without changing
      // layout proportions. Rebuilds automatically via the state listener.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
                widget.state.largeText ? 1.3 : 1.0),
          ),
          child: child!,
        );
      },
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
                builder: (_) => HomeScreen(appState: widget.state));
          case '/town':
            return MaterialPageRoute(
                builder: (_) => TownMapScreen(
                    appState: widget.state,
                    repository: widget.repository));
          case '/level':
            final levelId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => LevelScreen(
                    appState: widget.state,
                    repository: widget.repository,
                    levelId: levelId));
          case '/celebration':
            final levelId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => CelebrationScreen(
                    appState: widget.state,
                    repository: widget.repository,
                    levelId: levelId));
          case '/parents':
            return MaterialPageRoute(
                builder: (_) =>
                    ParentsScreen(appState: widget.state));
          default:
            return MaterialPageRoute(
                builder: (_) => HomeScreen(appState: widget.state));
        }
      },
    );
  }
}
