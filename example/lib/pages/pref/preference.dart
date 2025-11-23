import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master_example/ctx_extension.dart';
import 'package:pdf_master_example/pages/license/open_source_license.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kPrefDarkMode = 'pref_dark_mode';
const kPrefDarkModeFollowSystem = 'pref_dark_mode_follow_system';

bool _darkMode = false;
bool _darkModeFollowSystem = false;
ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
ValueNotifier<bool> followSystemNotifier = ValueNotifier(false);

Future<void> initDarkModePref() async {
  final prefs = await SharedPreferences.getInstance();
  _darkMode = prefs.getBool(kPrefDarkMode) ?? false;
  _darkModeFollowSystem = prefs.getBool(kPrefDarkModeFollowSystem) ?? true;

  darkModeNotifier.value = _darkMode;
  followSystemNotifier.value = _darkModeFollowSystem;

  if (_darkModeFollowSystem) {
    await _applySystemTheme();
  }
}

bool _isSystemDarkMode() {
  return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
}

Future<void> _applySystemTheme() async {
  final systemDarkMode = _isSystemDarkMode();
  if (_darkMode != systemDarkMode) {
    _darkMode = systemDarkMode;
    darkModeNotifier.value = systemDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefDarkMode, systemDarkMode);
  }
}

Future<void> onDarkModeChanged(bool value) async {
  final prefs = await SharedPreferences.getInstance();

  _darkMode = value;
  darkModeNotifier.value = value;
  await prefs.setBool(kPrefDarkMode, value);

  final systemDarkMode = _isSystemDarkMode();
  if (_darkModeFollowSystem && systemDarkMode != value) {
    _darkModeFollowSystem = false;
    followSystemNotifier.value = false;
    await prefs.setBool(kPrefDarkModeFollowSystem, false);
  }
}

Future<void> onFollowSystemChanged(bool value) async {
  final prefs = await SharedPreferences.getInstance();

  if (!value) {
    _darkModeFollowSystem = false;
    followSystemNotifier.value = false;
    await prefs.setBool(kPrefDarkModeFollowSystem, false);
  } else {
    _darkModeFollowSystem = true;
    followSystemNotifier.value = true;
    await prefs.setBool(kPrefDarkModeFollowSystem, true);

    final systemDarkMode = _isSystemDarkMode();
    if (_darkMode != systemDarkMode) {
      _darkMode = systemDarkMode;
      darkModeNotifier.value = systemDarkMode;
      await prefs.setBool(kPrefDarkMode, systemDarkMode);
    }
  }
}

Future<void> onSystemThemeChanged() async {
  if (_darkModeFollowSystem) {
    await _applySystemTheme();
  }
}

class PreferenceSwitch extends StatelessWidget {
  final String title;
  final String prefKey;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PreferenceSwitch({
    super.key,
    required this.prefKey,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor),
      height: 56,
      child: Row(
        children: [
          Text(title),
          Spacer(),
          CupertinoSwitch(value: value, activeTrackColor: Colors.blueAccent, onChanged: onChanged),
        ],
      ),
    );
  }
}

class PreferenceText extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const PreferenceText({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor),
        height: 56,
        child: Row(children: [Text(title), Spacer(), Icon(Icons.arrow_forward_ios_sharp, size: 12)]),
      ),
    );
  }
}

class PreferencePage extends StatefulWidget {
  const PreferencePage({super.key});

  @override
  State<PreferencePage> createState() => _PreferencePageState();
}

class _PreferencePageState extends State<PreferencePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PdfMasterAppBar(
            title: context.localizations.settings,
            leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
          ),
          SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: darkModeNotifier,
            builder: (context, darkMode, _) {
              return PreferenceSwitch(
                prefKey: kPrefDarkMode,
                title: context.localizations.darkMode,
                value: darkMode,
                onChanged: onDarkModeChanged,
              );
            },
          ),
          SizedBox(height: 1),
          ValueListenableBuilder<bool>(
            valueListenable: followSystemNotifier,
            builder: (context, followSystem, _) {
              return PreferenceSwitch(
                prefKey: kPrefDarkModeFollowSystem,
                title: context.localizations.followSystem,
                value: followSystem,
                onChanged: onFollowSystemChanged,
              );
            },
          ),
          SizedBox(height: 16),
          PreferenceText(
            title: context.localizations.openSource,
            onTap: () => Navigator.push(context, PDFMasterPageRouter(builder: (ctx) => OpenSourceListPage())),
          ),
        ],
      ),
    );
  }
}
