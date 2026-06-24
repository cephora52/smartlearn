// MbemNova — domain/user/valueobject/LienParrainage.java
package com.mbem.mbemlevel.domain.user.valueobject;

import com.mbem.mbemlevel.domain.shared.ValueObject;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.Objects;

/**
 * Value Object — code de parrainage unique.
 * Immuable. Généré aléatoirement à la demande.
 */
public record LienParrainage(String code) implements ValueObject {

    private static final SecureRandom RANDOM = new SecureRandom();

    public LienParrainage {
        Objects.requireNonNull(code, "Le code de parrainage ne peut pas être null");
        if (code.isBlank() || code.length() < 6) {
            throw new IllegalArgumentException("Code de parrainage invalide : " + code);
        }
    }

    /** Génère un code de parrainage aléatoire de 8 caractères URL-safe. */
    public static LienParrainage generer() {
        byte[] bytes = new byte[6];
        RANDOM.nextBytes(bytes);
        String code = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes).toUpperCase();
        return new LienParrainage(code.substring(0, 8));
    }

    /** URL complète du lien de parrainage. */
    public String toUrl(String baseUrl) {
        return baseUrl + "/register?ref=" + code;
    }
}
