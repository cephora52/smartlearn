# MbemNova — Référence API

Base URL : `https://mbemnova.com/api/v1`

Authentification : `Authorization: Bearer <jwt_token>`

## Auth (`/auth`)

| Méthode | Endpoint                  | Auth | Description                              |
|---------|---------------------------|------|------------------------------------------|
| POST    | `/auth/register`          | ❌   | Créer un compte apprenant (S02)          |
| POST    | `/auth/login`             | ❌   | Connexion — retourne JWT + refresh token |
| POST    | `/auth/refresh`           | ❌   | Rotation du refresh token                |
| POST    | `/auth/logout`            | ✅   | Blacklist JWT + révocation refresh token |
| POST    | `/auth/reset-password`    | ❌   | Demander le lien de reset MDP (S27)      |
| POST    | `/auth/new-password`      | ❌   | Confirmer le nouveau mot de passe        |
| GET     | `/auth/confirm-email`     | ❌   | Vérifier l'email (`?token=xxx`)          |
| GET     | `/auth/me`                | ✅   | Profil de l'utilisateur connecté         |

### Format de réponse auth

```json
{
  "success": true,
  "data": {
    "userId": "uuid",
    "prenom": "Alice",
    "email": "alice@mbemnova.com",
    "role": "APPRENANT",
    "accessToken": "eyJ...",
    "refreshToken": "abc123...",
    "expiresAt": "2025-01-02T08:00:00",
    "suspended": false
  }
}
```

## Cours (`/cours`)

| Méthode | Endpoint           | Auth | Description                               |
|---------|--------------------|------|-------------------------------------------|
| GET     | `/cours`           | ❌   | Catalogue paginé (`?niveau=DEBUTANT&page=0&size=12`) |
| GET     | `/cours/{id}`      | ❌   | Détail d'un cours                         |
| GET     | `/cours/slug/{s}`  | ❌   | Détail par slug URL                       |
| POST    | `/admin/cours`     | FORM | Créer un cours (brouillon)                |
| POST    | `/admin/cours/{id}/publier` | ADMIN | Publier un cours             |

## Progression (`/progression`)

| Méthode | Endpoint                               | Auth | Description            |
|---------|----------------------------------------|------|------------------------|
| POST    | `/progression/cours/{id}/commencer`    | ✅   | Commencer/reprendre    |
| POST    | `/progression/cours/{id}/terminer-lecon` | ✅ | Valider une leçon (+XP)|
| GET     | `/progression`                         | ✅   | Toutes mes progressions|
| GET     | `/progression/cours/{id}`              | ✅   | Progression sur un cours|

## Paiement (`/paiements`)

| Méthode | Endpoint                               | Auth  | Description              |
|---------|----------------------------------------|-------|--------------------------|
| POST    | `/paiements`                           | ADMIN | Enregistrer paiement cash|
| POST    | `/paiements/apprenants/{id}/suspendre` | ADMIN | Suspendre le compte      |
| POST    | `/paiements/apprenants/{id}/reactiver` | ADMIN | Réactiver le compte      |

## Sessions (`/sessions`)

| Méthode | Endpoint                        | Auth | Description              |
|---------|---------------------------------|------|--------------------------|
| GET     | `/sessions/cours/{id}`          | ❌   | Sessions disponibles     |
| POST    | `/sessions/{id}/inscrire`       | ✅   | S'inscrire à une session |

## Devoirs (`/devoirs`)

| Méthode | Endpoint                            | Auth  | Description               |
|---------|-------------------------------------|-------|---------------------------|
| POST    | `/devoirs/sessions/{id}`            | FORM  | Publier un devoir          |
| POST    | `/devoirs/soumettre`                | ✅    | Soumettre un rendu         |
| PATCH   | `/devoirs/rendus/{id}/corriger`     | FORM  | Corriger un rendu          |

## Certificats (`/certificats`)

| Méthode | Endpoint                          | Auth | Description                   |
|---------|-----------------------------------|------|-------------------------------|
| POST    | `/certificats/cours/{id}/generer` | ✅   | Générer mon certificat (S13)  |
| GET     | `/certificats/verify/{code}`      | ❌   | Vérification publique         |

## Talent (`/talents`)

| Méthode | Endpoint          | Auth | Description             |
|---------|-------------------|------|-------------------------|
| GET     | `/talents/{id}`   | ❌   | Profil public apprenant |
| GET     | `/talents/me`     | ✅   | Mon profil talent       |

## Communauté (`/communaute`)

| Méthode | Endpoint                                  | Auth | Description          |
|---------|-------------------------------------------|------|----------------------|
| GET     | `/communaute/cours/{id}/questions`        | ❌   | Questions d'un cours |
| POST    | `/communaute/cours/{id}/messages`         | ✅   | Poster une question  |
| GET     | `/communaute/messages/{id}/reponses`      | ❌   | Réponses à une question|

## Notifications (`/notifications`)

| Méthode | Endpoint                    | Auth | Description               |
|---------|-----------------------------|------|---------------------------|
| GET     | `/notifications`            | ✅   | Toutes mes notifications  |
| GET     | `/notifications/unread`     | ✅   | Non lues                  |
| PATCH   | `/notifications/read-all`   | ✅   | Tout marquer lu           |

## Admin (`/admin`)

| Méthode | Endpoint                         | Auth  | Description              |
|---------|----------------------------------|-------|--------------------------|
| POST    | `/admin/apprenants`              | ADMIN | Inscrire manuellement    |
| POST    | `/admin/utilisateurs/role`       | ADMIN | Changer le rôle          |
| GET     | `/admin/statistiques`            | ADMIN | Dashboard stats          |
| POST    | `/admin/tirage`                  | SUPER | Tirage au sort mensuel   |

## Format d'erreur standard

```json
{
  "success": false,
  "message": "Email ou mot de passe incorrect.",
  "error": { "code": "INVALID_CREDENTIALS" },
  "timestamp": "2025-01-01T08:00:00"
}
```

### Codes d'erreur HTTP

| Code | Signification             |
|------|---------------------------|
| 401  | UNAUTHORIZED, TOKEN_EXPIRED, INVALID_CREDENTIALS |
| 403  | ACCESS_DENIED, ACCOUNT_SUSPENDED, ACCOUNT_TEMPORARILY_LOCKED |
| 404  | RESOURCE_NOT_FOUND        |
| 409  | EMAIL_ALREADY_EXISTS      |
| 422  | VALIDATION_ERROR          |
| 429  | RATE_LIMIT_EXCEEDED       |
| 500  | INTERNAL_ERROR            |
