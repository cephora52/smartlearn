package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.util.List;

/** S14 — Mise à jour du profil talent */
public record MettreAJourProfilRequest(
    @Size(max = 100) String prenom,
    @Size(max = 100) String nom,
    @Size(max = 20)  String telephone,

    /** Bio professionnelle affichée sur le profil public */
    @Size(max = 1000) String bio,

    /** Titre professionnel : "Développeur Full Stack" */
    @Size(max = 200) String titreProfessionnel,

    /** Ville de résidence */
    @Size(max = 100) String ville,

    /** Lien LinkedIn */
    @Size(max = 500) String lienLinkedIn,

    /** Lien GitHub */
    @Size(max = 500) String lienGithub,

    /** Compétences : ["Java", "Spring Boot", "React"] */
    @Size(max = 20) List<@NotBlank @Size(max = 50) String> competences
) {}
