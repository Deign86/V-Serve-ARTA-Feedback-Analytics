// Generated config entrypoint for simple env overrides.
// Use --dart-define=BASE_API_URL=https://api.example.com when running/building to override.
const String baseApiUrl = String.fromEnvironment(
  'BASE_API_URL',
  defaultValue: 'http://localhost:5000',
);
