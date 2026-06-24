export const environment = {
  production:   true,
  apiUrl:       '/api/v1',
  wsUrl:        '/ws',
  useMock:      false,   // ← JAMAIS de mock en production
  autoFallback: false,
  version:      '1.0.0',
} as const;
