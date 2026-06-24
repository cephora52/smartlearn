// MbemNova — domain/shared/enums/Role.java
package com.mbem.mbemlevel.domain.shared.enums;

/**
 * Rôles utilisateurs MbemNova.
 * L'ordinal encode le niveau de privilège (croissant).
 */
public enum Role {
    /** Rôle par défaut à l'inscription — suit des cours. */
    APPRENANT,
    /** Crée des cours, gère des sessions, corrige des devoirs. */
    FORMATEUR,
    /** Gestion complète : paiements, inscriptions, statistiques. */
    ADMIN,
    /** Rôle technique maximal — gère les admins. Maximum 2 personnes. */
    SUPER_ADMIN;

    /** Préfixe requis par Spring Security pour @PreAuthorize. */
    public String toSpringRole() {
        return "ROLE_" + this.name();
    }

    /**
     * Ce rôle a-t-il au moins les droits du rôle cible ?
     * Exemple : {@code ADMIN.hasAtLeast(FORMATEUR)} → true
     */
    public boolean hasAtLeast(Role target) {
        return this.ordinal() >= target.ordinal();
    }
}
