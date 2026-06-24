// =============================================================================
// MbemNova — domain/shared/Email.java
// =============================================================================
package com.mbem.mbemlevel.domain.shared;

import java.util.Objects;

/**
 * Value Object représentant une adresse email validée.
 * Immuable — normalisée en minuscules à la construction.
 */
public final class Email implements ValueObject {

    private final String value;

    private Email(String value) {
        Objects.requireNonNull(value, "L'adresse email ne peut pas être null");
        String trimmed = value.trim().toLowerCase();
        if (trimmed.isEmpty()) {
            throw new IllegalArgumentException("L'adresse email ne peut pas être vide");
        }
        // Validation minimale dans le domaine — Bean Validation gère le format HTTP
        if (!trimmed.contains("@") || !trimmed.contains(".")) {
            throw new IllegalArgumentException("Format d'email invalide : " + value);
        }
        if (trimmed.length() > 255) {
            throw new IllegalArgumentException("Email trop long (max 255 chars)");
        }
        this.value = trimmed;
    }

    public static Email of(String value) {
        return new Email(value);
    }

    public String getValue() { return value; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Email e)) return false;
        return value.equals(e.value);
    }

    @Override
    public int hashCode() { return Objects.hash(value); }

    @Override
    public String toString() { return value; }
}
