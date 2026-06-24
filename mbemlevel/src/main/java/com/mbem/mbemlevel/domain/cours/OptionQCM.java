package com.mbem.mbemlevel.domain.cours;

/**
 * Option d'une question QCM.
 * Ex: { id: "A", texte: "Spring Boot est un framework Java" }
 */
public record OptionQCM(String id, String texte) {
    public OptionQCM {
        if (id == null || id.isBlank()) throw new IllegalArgumentException("id requis");
        if (texte == null || texte.isBlank()) throw new IllegalArgumentException("texte requis");
        if (!id.matches("[A-D]")) throw new IllegalArgumentException("id doit être A, B, C ou D");
    }
}
