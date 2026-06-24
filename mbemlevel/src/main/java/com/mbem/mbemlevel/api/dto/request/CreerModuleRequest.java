package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

/**
 * Création d'un module de cours avec toutes ses leçons.
 *
 * Un module regroupe des leçons sur un même thème.
 * Exemple : Module 1 "Introduction à Java" → 5 leçons
 */
public record CreerModuleRequest(

    @NotBlank @Size(max = 200)
    String titre,

    @Size(max = 500)
    String description,

    @Min(1)
    int ordre,

    /** XP bonus accordés quand tout le module est terminé */
    @Min(0) @Max(1000)
    int xpBonus,

    /**
     * Module accessible entièrement avant le seuil de paiement.
     * Typiquement vrai pour le module 1 (introduction gratuite).
     */
    boolean estGratuit,

    /**
     * Leçons du module dans l'ordre.
     * Minimum 1 leçon par module.
     */
    @NotEmpty
    @Valid
    List<CreerLeconRequest> lecons

) {}
