import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<List<Map<String, dynamic>>> searchPlayers(String query, {int limit = 10}) async {
  if (query.trim().isEmpty) return [];

  final response = await supabase.rpc(
    'search_players',
    params: {'query_text': query, 'limit_count': limit},
  );

  if (response.error != null) {
    print('Error: ${response.error!.message}');
    return [];
  }

  // The RPC returns a List<dynamic>
  return List<Map<String, dynamic>>.from(response.data);
}
