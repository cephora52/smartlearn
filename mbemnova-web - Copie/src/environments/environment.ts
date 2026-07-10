/**
 * MbemNova · Environment Development
 *
 * ╔══════════════════════════════════════════════════════════╗
 * ║  BASCULE MOCK ↔ API RÉELLE                               ║
 * ║                                                          ║
 * ║  useMock: true  → Données de test (aucun serveur requis) ║
 * ║  useMock: false → API Spring Boot (localhost:8080)       ║
 * ║                                                          ║
 * ║  Changer seulement cette variable — rien d'autre.       ║
 * ╚══════════════════════════════════════════════════════════╝
 */
export const environment = {
  production:   false,
  apiUrl:       'http://localhost:8080/api/v1',
  wsUrl:        'ws://localhost:8080/ws',

  // ← CHANGER ICI : true = mock | false = API Spring Boot
  useMock:      false,

  // Auto-fallback : si l'API retourne [] en dev, bascule sur mock
  autoFallback: true,
  version:      '1.0.0-dev',
} as const;
