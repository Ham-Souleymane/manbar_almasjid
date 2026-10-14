/// Configuration for the external VPS Media Server.
///
/// Ensures complete isolation by providing dedicated [appId] partitioning
/// so that files are kept strictly segregated from other apps (e.g. StayFix).
class MediaServerConfig {
  /// Base URL of the media VPS server.
  /// Can be configured at compile time via:
  /// `--dart-define=MEDIA_SERVER_BASE_URL=https://media.stayfix.co`
  static const String defaultBaseUrl = String.fromEnvironment(
    'MEDIA_SERVER_BASE_URL',
    defaultValue: 'https://media.stayfix.co',
  );

  /// Unique application identifier for dedicated storage isolation.
  /// Defaults to 'manbar_almasjid'.
  /// Can be overridden via:
  /// `--dart-define=MEDIA_SERVER_APP_ID=manbar_almasjid`
  static const String defaultAppId = String.fromEnvironment(
    'MEDIA_SERVER_APP_ID',
    defaultValue: 'manbar_almasjid',
  );

  /// Service API key if using server-to-server or API key auth.
  static const String defaultApiKey = String.fromEnvironment(
    'MEDIA_SERVER_API_KEY',
    defaultValue: '',
  );

  // Runtime overrides (useful for environment switching, staging, testing)
  static String? _overrideBaseUrl;
  static String? _overrideAppId;
  static String? _overrideApiKey;

  /// Effective Base URL with any trailing slashes stripped.
  static String get baseUrl {
    final raw = _overrideBaseUrl ?? defaultBaseUrl;
    return raw.replaceAll(RegExp(r'/+$'), '');
  }

  /// Effective App ID ensuring isolated storage.
  static String get appId => _overrideAppId ?? defaultAppId;

  /// Effective API Key if configured.
  static String get apiKey => _overrideApiKey ?? defaultApiKey;

  /// Set runtime overrides for testing or dynamic config.
  static void setOverrides({
    String? baseUrl,
    String? appId,
    String? apiKey,
  }) {
    if (baseUrl != null) _overrideBaseUrl = baseUrl;
    if (appId != null) _overrideAppId = appId;
    if (apiKey != null) _overrideApiKey = apiKey;
  }

  /// Reset runtime overrides back to environment defaults.
  static void reset() {
    _overrideBaseUrl = null;
    _overrideAppId = null;
    _overrideApiKey = null;
  }
}
