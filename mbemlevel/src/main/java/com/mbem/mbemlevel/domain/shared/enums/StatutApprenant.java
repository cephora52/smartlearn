// MbemNova — domain/shared/enums/StatutApprenant.java
package com.mbem.mbemlevel.domain.shared.enums;

/**
 * Cycle de vie du compte apprenant.
 * <pre>
 * INSCRIT → ACTIF (premier cours commencé)
 * ACTIF   → SUSPENDU (J+10 sans paiement)
 * SUSPENDU→ ACTIF (après régularisation)
 * ACTIF   → CERTIFIE (premier certificat obtenu)
 * </pre>
 */
public enum StatutApprenant {
    /** Compte créé, aucun cours commencé. */
    INSCRIT,
    /** En cours d'apprentissage, paiements à jour. */
    ACTIF,
    /** Compte supprimé. */
    SUPPRIME,
    /** Accès cours bloqué — retard paiement. Progression préservée. */
    SUSPENDU,
    /** A obtenu au moins un certificat. */
    CERTIFIE
}
