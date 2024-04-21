import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tswiri/routes.dart';
import 'package:tswiri/settings/settings.dart';
import 'package:tswiri/theme.dart';
import 'providers.dart';

import 'package:tswiri_database/space/space.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final settings = Settings(prefs: prefs);
  await settings.loadSettings();

  settingsProvider = ChangeNotifierProvider<Settings>(
    (ref) => settings,
  );

  final space = Space();
  await space.loadSpace(spacePath: settings.spacePath);

  spaceProvider = ChangeNotifierProvider<Space>(
    (ref) => space,
  );

  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final settings = ref.watch(settingsProvider);
          return MaterialApp(
            title: 'Tswiri App',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: settings.themeMode,
            debugShowCheckedModeBanner: false,
            initialRoute: Routes.home,
            routes: Routes().allRoutes,
          );
        },
      ),
    ),
  );
}
