import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/theme/theme_controller.dart';
import 'data/providers.dart';
import 'data/tplink/router_credentials.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // A broken Android keystore must not stop the app from opening.
  RouterCredentials? credentials;
  try {
    credentials = await const RouterCredentialsStore(FlutterSecureStorage())
        .read();
  } catch (_) {
    credentials = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialRouterCredentialsProvider.overrideWithValue(credentials),
      ],
      child: const NexusApp(),
    ),
  );
}
