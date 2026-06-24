// MbemNova — domain/shared/enums/StatutPaiement.java
package com.mbem.mbemlevel.domain.shared.enums;

/**
 * Statut d'une tranche de paiement.
 * <pre>
 * EN_ATTENTE → PAYE (admin confirme)
 * EN_ATTENTE → EN_RETARD (échéance dépassée)
 * EN_RETARD  → PAYE (après régularisation)
 * EN_ATTENTE → MORATOIRE (délai accordé)
 * </pre>
 */
public enum StatutPaiement {
    EN_ATTENTE, PAYE, EN_RETARD, MORATOIRE, ANNULE
}
