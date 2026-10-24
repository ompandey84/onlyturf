import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://thvdxomjwppiqrikedng.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmR4b21qd3BwaXFyaWtlZG5nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2ODk2MDgsImV4cCI6MjA4NTI2NTYwOH0.8vkvmPFzpGgBMJBoySnQ-QzpEpWqfMKs_UQwU5uJ5KI');
  try {
    final response = await supabase.from('facilities').select().order('created_at', ascending: false).limit(8);
    print("Fetched facilities using order created_at: \${response.length}");
    for (var r in response) {
      print("Facility: \${r['name']}, Location: \${r['location']}, created_at: \${r['created_at']}");
    }
  } catch (e) {
    print("Error ordering by created_at: \$e");
  }
}
