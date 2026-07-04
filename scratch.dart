import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final client = SupabaseClient('url', 'key');
  client.channel('public:all').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    callback: (PostgresChangePayload payload) {
      print(payload.table);
    }
  ).subscribe();
}
