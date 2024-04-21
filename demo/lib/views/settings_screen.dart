import 'package:flutter/material.dart';
import 'package:tswiri/extensions.dart';
import 'package:tswiri/providers.dart';
import 'package:tswiri/views/abstract_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends AbstractScreen<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeTile = ListTile(
      title: const Text('Theme'),
      trailing: DropdownMenu(
        initialSelection: ref.watch(settingsProvider).themeMode,
        dropdownMenuEntries: ThemeMode.values.map(
          (themeMode) {
            return DropdownMenuEntry(
              value: themeMode,
              label: themeMode.name.capitalizeFirstCharacter,
            );
          },
        ).toList(),
        onSelected: (value) {
          if (value == null) return;
          ref.read(settingsProvider).setTheme(value);
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Divider(),
            themeTile,
          ],
        ),
      ),
    );
  }
}
