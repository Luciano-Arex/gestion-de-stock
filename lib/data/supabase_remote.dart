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
  Future<void> upsertProducts(List<Map<String, Object?>> rows) async {
    await client.from('products').upsert(rows, onConflict: 'id');
  }

  @override
  Future<void> insertMovements(List<Map<String, Object?>> rows) async {
    await client.from('movements').upsert(rows, onConflict: 'id', ignoreDuplicates: true);
  }

  @override
  Future<({List<Map<String, Object?>> products, List<Map<String, Object?>> movements})>
      changesSince(int cursor, int limit) async {
    final results = await Future.wait([
      client.from('products').select().gt('seq', cursor).order('seq').limit(limit),
      client.from('movements').select().gt('seq', cursor).order('seq').limit(limit),
    ]);
    return (products: results[0], movements: results[1]);
  }
}
