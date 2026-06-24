# MbemNova — Architecture technique

## Architecture hexagonale (Ports & Adapters)

### Principes

L'architecture hexagonale isole la logique métier (Domain + Application)
du monde extérieur (Infrastructure, API). Le Domain ne connaît ni Spring,
ni JPA, ni Redis — seulement du Java pur.

```
┌─────────────────────────────────────────────────────────┐
│  API (Controllers, Filters, DTOs HTTP)                  │
│         ↓ Commands/Queries                               │
│  Application (Use Cases, Event Handlers)                │
│         ↓ Ports (interfaces)                             │
│  Domain (Agrégats, Value Objects, Domain Events)        │
│         ↑ Implémentations                                │
│  Infrastructure (JPA, Redis, Email, PDF, Storage)       │
└─────────────────────────────────────────────────────────┘
```

### Règles strictes

1. **Domain** — Zéro dépendance Spring/JPA. Testé sans contexte Spring.
2. **Application** — Orchestre le Domain. Dépend uniquement des Ports (interfaces).
3. **Infrastructure** — Implémente les Ports. Jamais appelée directement par le Domain.
4. **API** — Appelle les Use Cases. Ne parle jamais directement aux JPA Repositories.

Vérifiées à chaque build par `ArchitectureTest.java` (ArchUnit).

### Stack technique

| Composant      | Technologie                         |
|----------------|-------------------------------------|
| Framework      | Spring Boot 4.0.5 (Jakarta EE 11)  |
| BDD            | PostgreSQL 16 + Flyway 10           |
| Cache          | Redis 7.2 (Lettuce)                 |
| Sécurité       | Spring Security 7 + Nimbus JOSE JWT |
| Mapping        | MapStruct 1.6.3                     |
| PDF            | iText 8 + html2pdf                  |
| Storage        | MinIO (S3-compatible)               |
| Email          | Spring Mail + Thymeleaf             |
| Monitoring     | Actuator + Micrometer + Prometheus  |
| Tests          | JUnit 5 + Testcontainers + ArchUnit |
| CI/CD          | GitHub Actions                      |

### Scénarios couverts (28/28)

| Script | Scénarios |
|--------|-----------|
| s08    | S02 (inscription), S03 (connexion), S27 (reset MDP) |
| s09    | S04 (catalogue), S05 (commencer cours), S06 (leçon+QCM), S07 (seuil paiement) |
| s10    | S08 (paiement cash), S16 (relances), S18 (suspension) |
| s11    | S09 (inscription session), S10 (créneaux), S11 (devoir+rendu), S23 (correction) |
| s12    | S12 (communauté Q&R), S13 (certificat), S14 (profil talent), S15 (parrainage) |
| s13    | S19 (créer cours), S20 (créer session), S21 (inscription manuelle) |
|        | S24 (tirage), S25 (stats admin), S26 (rôles) |

