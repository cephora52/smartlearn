# MbemNova — Guide Sécurité

## Architecture de sécurité

```
Client → Nginx (TLS 1.3) → RateLimitFilter → JwtAuthFilter → Spring Security
                                                     ↓
                                             SecurityContext
                                                     ↓
                                          @PreAuthorize RBAC
```

## JWT (JSON Web Tokens)

### Structure
```
Header  : {"alg":"HS256","typ":"JWT"}
Payload : {"sub":"uuid","email":"...","role":"APPRENANT","jti":"uuid","exp":...}
```

### Sécurités en place
- Secret minimum 256 bits (32 chars) — dérivé via SHA-256
- JTI unique par token → blacklist possible à la déconnexion
- Expiration : 24h (access) · 30j (refresh)
- Refresh tokens : SHA-256 en base, jamais le brut, rotation à chaque usage
- Blacklist Redis : TTL = durée restante du token (auto-expiration)

## Protection brute-force

- Compteur d'échecs par compte en base de données
- Blocage temporaire 30 min après 5 échecs consécutifs
- Réinitialisation automatique à la connexion réussie
- Message d'erreur générique (pas d'information sur l'existence du compte)

## Rate Limiting (Bucket4j)

| Endpoint              | Limite         |
|-----------------------|----------------|
| POST /auth/login      | 10/min par IP  |
| POST /auth/register   | 5/min par IP   |
| POST /reset-password  | 3/heure par IP |
| Autres endpoints API  | 100/min par IP |

## RGPD (Données personnelles)

### Données collectées

| Donnée         | Finalité                      | Durée conservation    |
|----------------|-------------------------------|-----------------------|
| Prénom, email  | Authentification, certificats | Durée compte + 2 ans  |
| Téléphone      | WhatsApp, urgences            | Durée compte          |
| IP de connexion| Sécurité, audit               | 90 jours              |
| Données paiement| Facturation, comptabilité    | 10 ans (légal)        |
| Progression    | Service principal             | Durée compte          |
| CV uploadé     | Profil talent                 | Jusqu'à suppression   |

### Droits des utilisateurs
1. **Accès** : données disponibles depuis le profil (délai 30j si demande formelle)
2. **Rectification** : modification directe depuis le profil
3. **Effacement** : suppression compte depuis les paramètres (sauf données légales)
4. **Opposition** : opt-out notifications depuis le profil

## Audit Log

Toutes les actions sensibles sont tracées de façon immuable :
- `LOGIN_SUCCESS / LOGIN_FAILURE / LOGOUT`
- `REGISTER / EMAIL_VERIFIED`
- `PASSWORD_RESET_REQUESTED / PASSWORD_RESET_DONE`
- `PAYMENT_ACTIVATED / ACCOUNT_SUSPENDED / ACCOUNT_REACTIVATED`
- `ROLE_CHANGED / DATA_EXPORTED`

Immuabilité garantie par un trigger PostgreSQL (V8__create_securite.sql).

## Headers de sécurité HTTP

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'; frame-ancestors 'none'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Cache-Control: no-store, no-cache (endpoints API)
```
