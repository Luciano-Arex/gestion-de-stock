import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync.dart';

/// Adresse et clé publique du projet Supabase, fournies à la compilation :
/// `flutter build apk --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_KEY=…`
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
bool get supabaseConfigured => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

/// Tables décrites dans `supabase/schema.sql`.
class SupabaseRemote implements SyncRemote {
  SupabaseRemote(this.client);

  final SupabaseClient client;

  @override
  Future<void> upsertCategories(List<Map<String, Object?>> rows) async {
    await client.from('categories').upsert(rows, onConflict: 'id');
  }

  @override
  Future<void> upsertProducts(List<Map<String, Object?>> rows) async {
    await client.from('products').upsert(rows, onConflict: 'id');
  }

  @override
  Future<void> insertMovements(List<Map<String, Object?>> rows) async {
    await client.from('movements').upsert(rows, onConflict: 'id', ignoreDuplicates: true);
  }

  @override
  Future<RemoteChanges> changesSince(int cursor, int limit) async {
    final results = await Future.wait([
      client.from('categories').select().gt('seq', cursor).order('seq').limit(limit),
      client.from('products').select().gt('seq', cursor).order('seq').limit(limit),
      client.from('movements').select().gt('seq', cursor).order('seq').limit(limit),
    ]);
    return (categories: results[0], products: results[1], movements: results[2]);
  }
}
