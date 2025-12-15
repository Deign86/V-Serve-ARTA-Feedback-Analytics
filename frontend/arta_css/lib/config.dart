// Centralized build-time configuration flags
// Use `--dart-define=USER_ONLY_MODE=true` when building to enable user-only mode
const bool kUserOnlyMode = bool.fromEnvironment('USER_ONLY_MODE', defaultValue: false);
// Generated config entrypoint for simple env overrides.
// Use --dart-define=BASE_API_URL=https://api.example.com when running/building to override.
const String baseApiUrl = String.fromEnvironment(
  'BASE_API_URL',
  defaultValue: 'http://localhost:5000',
);
