package com.mbem.mbemlevel.infrastructure.persistence.entity;

/**
 * PATCH NOTE — UtilisateurJpaEntity
 *
 * Ajouter ce champ dans UtilisateurJpaEntity existante :
 *
 *   @Column(name = "code_parrainage", length = 20, unique = true)
 *   private String codeParrainage;
 *
 *   public String getCodeParrainage() { return codeParrainage; }
 *   public void setCodeParrainage(String code) { this.codeParrainage = code; }
 *
 * Ce champ est ajouté par la migration V15__create_parrainage_complet.sql
 * qui contient : ALTER TABLE utilisateurs ADD COLUMN IF NOT EXISTS code_parrainage VARCHAR(20) UNIQUE;
 *
 * Généré automatiquement à l'initialisation du compte par InscrireApprenantUseCase.
 */
public final class UtilisateurCodeParrainagePatch {
    private UtilisateurCodeParrainagePatch() {}
}
