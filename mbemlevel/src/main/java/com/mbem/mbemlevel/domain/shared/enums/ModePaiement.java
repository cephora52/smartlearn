// MbemNova — domain/shared/enums/ModePaiement.java
package com.mbem.mbemlevel.domain.shared.enums;

/**
 * Modes de paiement acceptés.
 * CASH : actif dès le lancement.
 * MOBILE_MONEY / ONLINE : Phase 2.
 */
public enum ModePaiement {
    /** Paiement physique — activé manuellement par l'admin. */
    CASH,
    /** MTN Money ou Orange Money. */
    MOBILE_MONEY,
    /** Carte bancaire via Stripe/PayDunya. */
    ONLINE
}
