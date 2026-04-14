import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/jbc_repository.dart';
import '../data/repositories/noop_repository.dart';
import '../data/repositories/supabase_repository.dart';
import 'profile/profile_store.dart';

class AppBootstrap {
  AppBootstrap({
    required this.profileStore,
    required this.repository,
  });

  final ProfileStore profileStore;
  final JbcRepository repository;

  bool get hasRemote => repository is! NoopRepository;

  static Future<AppBootstrap> load(SharedPreferences prefs) async {
    const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    final store = ProfileStore(prefs);

    if (url.isEmpty || key.isEmpty) {
      return AppBootstrap(
        profileStore: store,
        repository: const NoopRepository(),
      );
    }

    await Supabase.initialize(url: url, anonKey: key);

    final client = Supabase.instance.client;
    try {
      await client.auth.signInAnonymously();
    } catch (_) {
      // Login anônimo opcional (depende do projeto Supabase). Operações usam a chave anon.
    }

    return AppBootstrap(
      profileStore: store,
      repository: SupabaseRepository(client),
    );
  }
}
