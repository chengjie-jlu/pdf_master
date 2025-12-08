import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf_master/pdf_master.dart';
import 'package:pdf_master_example/ctx_extension.dart';
import 'package:pdf_master_example/pages/license/open_source_license.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kPrefDarkMode = 'pref_dark_mode';
const kPrefDarkModeFollowSystem = 'pref_dark_mode_follow_system';
const kPrefImmersiveMode = 'pref_immersive_mode';
const kPrefAppBarPadding = 'pref_app_bar_padding';

bool _darkMode = false;
bool _darkModeFollowSystem = false;
ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
ValueNotifier<bool> followSystemNotifier = ValueNotifier(false);
ValueNotifier<bool> immersiveModeNotifier = ValueNotifier(false);
ValueNotifier<PaddingChoice> appBarPaddingNotifier = ValueNotifier(PaddingChoice.none);

Future<void> initDarkModePref() async {
  final prefs = await SharedPreferences.getInstance();
  _darkMode = prefs.getBool(kPrefDarkMode) ?? false;
  _darkModeFollowSystem = prefs.getBool(kPrefDarkModeFollowSystem) ?? true;
  immersiveModeNotifier.value = prefs.getBool(kPrefImmersiveMode) ?? false;
  if (prefs.containsKey(kPrefAppBarPadding)) {
    final boolValue =  prefs.getBool(kPrefAppBarPadding);
    if(boolValue == true){
      appBarPaddingNotifier.value = PaddingChoice.yes;
    }else{
      appBarPaddingNotifier.value = PaddingChoice.no;
    }
  } else {
    appBarPaddingNotifier.value = PaddingChoice.none;
  }

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

Future<void> onImmersiveModeChanged(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  immersiveModeNotifier.value = value;
  await prefs.setBool(kPrefImmersiveMode, value);
}

Future<void> onAppBarPaddingChanged(PaddingChoice? value) async {
  final prefs = await SharedPreferences.getInstance();
  appBarPaddingNotifier.value = value ?? PaddingChoice.none;
  if (value == PaddingChoice.none) {
    await prefs.remove(kPrefAppBarPadding);
  } else if (value == PaddingChoice.yes) {
    await prefs.setBool(kPrefAppBarPadding, true);
  } else if (value == PaddingChoice.no) {
    await prefs.setBool(kPrefAppBarPadding, false);
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

enum PaddingChoice { yes, no, none }

class PreferenceSegmentedControl extends StatelessWidget {
  final String title;
  final PaddingChoice groupValue;
  final ValueChanged<PaddingChoice?> onValueChanged;

  const PreferenceSegmentedControl({
    super.key,
    required this.title,
    required this.groupValue,
    required this.onValueChanged,
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
          CupertinoSlidingSegmentedControl<PaddingChoice>(
            groupValue: groupValue,
            onValueChanged: onValueChanged,
            children: const {
              PaddingChoice.none: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('Default')), // Add to l10n ideally
              PaddingChoice.yes: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('On')),
              PaddingChoice.no: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('Off')),
            },
          ),
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
          SizedBox(height: 1),
          ValueListenableBuilder<bool>(
            valueListenable: immersiveModeNotifier,
            builder: (context, immersive, _) {
              return PreferenceSwitch(
                prefKey: kPrefImmersiveMode,
                title: context.localizations.immersiveMode,
                value: immersive,
                onChanged: onImmersiveModeChanged,
              );
            },
          ),
          SizedBox(height: 1),
          // 6. ADD THE UI CONTROL
          ValueListenableBuilder<PaddingChoice>(
            valueListenable: appBarPaddingNotifier,
            builder: (context, paddingValue, _) {
              return PreferenceSegmentedControl(
                title: "AppBar Padding", // Add to l10n
                groupValue: paddingValue,
                onValueChanged: onAppBarPaddingChanged,
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