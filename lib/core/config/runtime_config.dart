class RuntimeConfig {
  const RuntimeConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'WORKFLOW_API_BASE_URL',
    defaultValue: 'https://workflow.gudeteknoloji.com.tr/api',
  );
}
