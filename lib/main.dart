import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/bootstrap.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bootstrap = await AppBootstrap.load(prefs);
  runApp(
    ProviderScope(
      overrides: [
        bootstrapProvider.overrideWithValue(bootstrap),
      ],
      child: const JbcApp(),
    ),
  );
}
