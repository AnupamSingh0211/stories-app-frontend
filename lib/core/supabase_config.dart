class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qajehfpfvahzkjkuqpdp.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_Bg2IPlT0iZnzai75WW8TOQ_kIrpgPXO',
  );
}
