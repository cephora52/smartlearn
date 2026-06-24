// =============================================================================
// MbemNova — domain/shared/Money.java
//
// Value Object représentant un montant monétaire en FCFA (XAF).
// Immuable — toute opération retourne un nouvel objet.
// Utilise BigDecimal pour éviter les erreurs d'arrondi des double.
// =============================================================================
package com.mbem.mbemlevel.domain.shared;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.NumberFormat;
import java.util.Locale;
import java.util.Objects;

/**
 * Montant monétaire en FCFA (Franc CFA Afrique Centrale — XAF).
 *
 * <h3>Pourquoi pas un simple long ?</h3>
 * <p>Un {@code long} force l'appelant à gérer lui-même les règles métier
 * (non-négatif, calcul de pourcentage…). {@code Money} les encapsule
 * et garantit leur respect à la construction.</p>
 *
 * <h3>Exemple d'utilisation</h3>
 * <pre>{@code
 * Money prix    = Money.of(50_000);         // 50 000 FCFA
 * Money acompte = prix.pct(30);             // 15 000 FCFA
 * Money reste   = prix.minus(acompte);      // 35 000 FCFA
 * prix.toDisplay();                          // "50 000 FCFA"
 * }</pre>
 */
public final class Money implements ValueObject {

    /** Devise fixe — FCFA Afrique Centrale. */
    public static final String DEVISE = "XAF";

    /** Constante zéro — utiliser plutôt que {@code Money.of(0)}. */
    public static final Money ZERO = new Money(BigDecimal.ZERO);

    private final BigDecimal amount;

    // ── Construction ──────────────────────────────────────────────────────────

    private Money(BigDecimal amount) {
        if (amount == null) {
            throw new IllegalArgumentException("Le montant ne peut pas être null");
        }
        if (amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Le montant ne peut pas être négatif : " + amount);
        }
        // Toujours 2 décimales pour la cohérence interne
        this.amount = amount.setScale(2, RoundingMode.HALF_UP);
    }

    /** Crée depuis un entier (cas courant en FCFA sans décimale). */
    public static Money of(long amount) {
        return new Money(BigDecimal.valueOf(amount));
    }

    /** Crée depuis un BigDecimal (résultats de calculs). */
    public static Money of(BigDecimal amount) {
        return new Money(amount);
    }

    // ── Opérations arithmétiques ──────────────────────────────────────────────

    /** Addition — retourne un nouveau {@code Money}. */
    public Money plus(Money other) {
        return new Money(this.amount.add(requireNonNull(other).amount));
    }

    /**
     * Soustraction — retourne un nouveau {@code Money}.
     * @throws IllegalArgumentException si le résultat serait négatif.
     */
    public Money minus(Money other) {
        return new Money(this.amount.subtract(requireNonNull(other).amount));
    }

    /**
     * Calcule un pourcentage de ce montant.
     * @param percentage Valeur entre 0.0 et 100.0 (ex: 30.0 pour 30%)
     */
    public Money pct(double percentage) {
        if (percentage < 0 || percentage > 100) {
            throw new IllegalArgumentException(
                "Pourcentage invalide : " + percentage + " (doit être entre 0 et 100)");
        }
        return new Money(
            this.amount
                .multiply(BigDecimal.valueOf(percentage / 100.0))
                .setScale(2, RoundingMode.HALF_UP)
        );
    }

    // ── Comparaisons ─────────────────────────────────────────────────────────

    public boolean isZero()                    { return amount.compareTo(BigDecimal.ZERO) == 0; }
    public boolean isPositive()                { return amount.compareTo(BigDecimal.ZERO) > 0; }
    public boolean isGreaterThan(Money other)  { return amount.compareTo(requireNonNull(other).amount) > 0; }
    public boolean isGreaterOrEq(Money other)  { return amount.compareTo(requireNonNull(other).amount) >= 0; }
    public boolean isLessThan(Money other)     { return amount.compareTo(requireNonNull(other).amount) < 0; }

    // ── Accesseurs ────────────────────────────────────────────────────────────

    public BigDecimal getAmount() { return amount; }

    /** Retourne le montant arrondi en entier (FCFA sans centimes). */
    public long toLong() {
        return amount.setScale(0, RoundingMode.HALF_UP).longValueExact();
    }

    /** Format d'affichage localisé : "50 000 FCFA". */
    public String toDisplay() {
        NumberFormat nf = NumberFormat.getNumberInstance(Locale.FRENCH);
        nf.setMaximumFractionDigits(0);
        return nf.format(amount) + " FCFA";
    }

    // ── Equals / hashCode / toString ─────────────────────────────────────────

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Money m)) return false;
        return amount.compareTo(m.amount) == 0; // compareTo ignorant les trailing zeros
    }

    @Override
    public int hashCode() {
        return Objects.hash(amount.stripTrailingZeros());
    }

    @Override
    public String toString() {
        return amount + " " + DEVISE;
    }

    private static Money requireNonNull(Money m) {
        return Objects.requireNonNull(m, "L'autre montant ne peut pas être null");
    }
}
