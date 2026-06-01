import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jam_sync/shared/utils/song_templates.dart';

final appInitProvider = FutureProvider<void>((ref) async {
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://hulqxdpctueedviciken.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1bHF4ZHBjdHVlZWR2aWNpa2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4NzY4NDksImV4cCI6MjA4NDQ1Mjg0OX0.Mk5hFfizbXzZYgJWik4x1TeiKtZ050JVGVEc7CcA1Ds',
    
  );

  await loadSongTemplatesFromSupabase();
});
