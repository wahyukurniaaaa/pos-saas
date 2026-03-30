import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Stream provider that listens to real-time auth state changes.
final supabaseAuthStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Synchronous provider for the current Supabase session.
final supabaseSessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(supabaseAuthStateProvider);
  return authState.value?.session ?? Supabase.instance.client.auth.currentSession;
});

/// Provider for the currently authenticated Supabase user.
final supabaseUserProvider = Provider<User?>((ref) {
  final session = ref.watch(supabaseSessionProvider);
  return session?.user;
});
