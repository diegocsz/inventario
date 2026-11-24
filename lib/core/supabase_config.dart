class SupabaseConfig {
  // Introduce aqui los datos publicos de tu proyecto. Nunca uses service_role.
  static const String url = 'https://dynybxgiyaiserarextm.supabase.co';
  static const String publishableKey = 'sb_publishable_eGt2ETYz3U3yyBIc-TwVaw_4ZaRrRW5';

  static bool get isConfigured =>
      url.startsWith('https://') && !publishableKey.startsWith('TU_');
}
