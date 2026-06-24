// =============================================================================
// MbemNova — domain/shared/ValueObject.java
// =============================================================================
package com.mbem.mbemlevel.domain.shared;

/**
 * Marqueur pour les Value Objects du domaine.
 *
 * <p>Un Value Object est immuable et défini par ses attributs (pas par une identité).
 * Toute opération retourne un nouvel objet — jamais de mutation.</p>
 *
 * <p><b>Exemples MbemNova</b> : {@code Money}, {@code Email},
 * {@code ProfilTalent}, {@code LienParrainage}.</p>
 */
public interface ValueObject {
    // Marqueur — pas de méthodes obligatoires.
    // L'immuabilité est une convention, pas une contrainte Java.
}
