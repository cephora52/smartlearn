# Corrections s23 — MbemNova

## 7 incohérences corrigées

| # | Fichier | Problème | Correction |
|---|---------|----------|-----------|
| 1 | `WhatsAppPort.java` | `envoyerMessage()` vs `envoyer()` | Unifié sur `envoyer()` + méthodes default |
| 2 | `Moratoire.java` | `accorder(UUID, String)` vs `accorder(UUID, LocalDate)` | Signature corrigée |
| 3 | `Cours.java` | `publier()` sans `statut="PUBLIE"` + setters manquants | Corrigé + 8 setters ajoutés |
| 4 | `CoursResponse.java` | `fromEntity()` absent | Ajouté aux côtés de `from()` |
| 5 | `PaiementRepository.java` | `findByIdAndApprenantId()` absent | Méthode ajoutée |
| 6 | `pom.xml` | `thumbnailator` + `spring-cloud-circuitbreaker` absents | `pom_additions.xml` généré |
| 7 | `TraiterMoratoireUseCase.java` | Appel `accorder(LocalDate)` sur ancien domain | Réécrit |

## Ce qui reste à faire manuellement

1. **pom.xml** — Copier le contenu de `pom_additions.xml` dans `<dependencies>`
2. **PaiementJpaRepository** — Ajouter `findByIdAndApprenantId(UUID, UUID)`
3. **PaiementRepositoryAdapter** — Implémenter la nouvelle méthode
4. **UtilisateurJpaEntity** — Ajouter `codeParrainage` + `deleted_at` (soft delete)
5. **UtilisateurJpaRepository** — Ajouter `findInscritsSansProgressionEntre()`
6. **ProgressionJpaRepository** — Ajouter `findSeuilAtteintNonPayeEntre()`

## Ordre d'exécution final complet

```bash
bash s01_pom_config.sh .          # existant
bash s02_structure.sh .            # existant
bash s03_domain.sh .               # existant
bash s04_application_auth.sh .     # existant
bash s05_migrations_sql.sh .       # existant
bash s06_jpa_infrastructure.sh .   # existant
bash s07_jwt_securite.sh .         # existant
bash s08_api_security.sh .         # existant
bash s09_cours_progression.sh .    # existant
bash s10_paiement.sh .             # existant
bash s11_session_devoir.sh .       # existant
bash s12_certificat_talent_communaute.sh . # existant
bash s13_admin_gamification.sh .   # existant
bash s14_devops.sh .               # existant
bash s15_tests_docs.sh .           # existant
# ── Nouveaux scripts (ordre important) ──
bash s16_migrations_manquantes.sh .
bash s17_jpa_entities_mappers_manquants.sh .
bash s18_lms_core_contenu.sh .
bash s19_usecases_manquants.sh .
bash s20_completions_finales.sh .
bash s21_lms_production_complet.sh .
bash s22_performance_enterprise.sh .
bash s23_corrections_incoherences.sh .    # CE SCRIPT — en dernier
```
