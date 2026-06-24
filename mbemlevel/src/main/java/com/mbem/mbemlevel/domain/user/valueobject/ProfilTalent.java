// MbemNova — domain/user/valueobject/ProfilTalent.java
package com.mbem.mbemlevel.domain.user.valueobject;

import com.mbem.mbemlevel.domain.shared.ValueObject;

/**
 * Value Object représentant le profil public d'un apprenant
 * dans la vitrine Talents (visible par les recruteurs).
 * Immuable — utiliser withXxx() pour créer des variantes.
 */
public record ProfilTalent(
    String ville,
    String bio,
    String lienPortfolio,
    String lienCv,
    String lienLinkedin,
    String lienGithub,
    boolean disponiblePourEmploi
) implements ValueObject {

    /** ProfilTalent vide — valeur par défaut à l'inscription. */
    public static ProfilTalent vide() {
        return new ProfilTalent(null, null, null, null, null, null, false);
    }

    public ProfilTalent withDisponible(boolean dispo) {
        return new ProfilTalent(ville, bio, lienPortfolio, lienCv, lienLinkedin, lienGithub, dispo);
    }
}
