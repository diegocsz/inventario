class SupabaseConfig {
  // Introduce aqui los datos publicos de tu proyecto. Nunca uses service_role.
  static const String url = 'TU_URL_SUPABASE';
  static const String publishableKey = 'TU_CLAVE_PUBLICABLE_SUPABASE';

  static bool get isConfigured =>
      url.startsWith('https://') && !publishableKey.startsWith('TU_');
}
