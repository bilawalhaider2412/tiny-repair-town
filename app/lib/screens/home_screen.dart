/// Home screen (spec §10): big Play button + smaller Parents control,
/// first-run language selection, EN/UR toggle.
library;

import 'package:flutter/material.dart';
import 'package:tiny_repair_town/core/localization.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../widgets/big_button.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _pickerShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First-run language selection (spec §10): shown once, never blocks play.
    // Dismissible: a child can always reach Play; dismissing keeps the
    // current language and still records the choice as made.
    if (!_pickerShown && !widget.appState.languagePicked) {
      _pickerShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => _LanguagePicker(appState: widget.appState),
        ).then((_) {
          if (!widget.appState.languagePicked) {
            widget.appState.markLanguagePicked();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final lang = appState.lang;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handyman,
                    size: 96, color: TownTheme.coral),
                const SizedBox(height: 16),
                Text(
                  tr('appTitle', lang),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                BigButton(
                  label: tr('play', lang),
                  icon: Icons.play_arrow,
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/town'),
                  color: TownTheme.green,
                  buttonKey: const Key('home_play'),
                ),
                const SizedBox(height: 16),
                BigButton(
                  label: tr('forParents', lang),
                  icon: Icons.family_restroom,
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/parents'),
                  color: TownTheme.yellow,
                  buttonKey: const Key('home_parents'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  key: const Key('home_language_toggle'),
                  onPressed: () => appState.setLanguage(
                      lang == 'en' ? 'ur' : 'en'),
                  child: Text(
                    lang == 'en' ? 'اردو' : 'English',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  final AppState appState;
  const _LanguagePicker({required this.appState});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Language / زبان'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BigButton(
            label: 'English',
            onPressed: () => _choose(context, 'en'),
            buttonKey: const Key('pick_english'),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: 'اردو',
            onPressed: () => _choose(context, 'ur'),
            buttonKey: const Key('pick_urdu'),
          ),
        ],
      ),
    );
  }

  Future<void> _choose(BuildContext context, String lang) async {
    await appState.setLanguage(lang);
    await appState.markLanguagePicked();
    if (context.mounted) Navigator.of(context).pop();
  }
}
