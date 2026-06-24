// MbemNova — domain/user/Formateur.java
package com.mbem.mbemlevel.domain.user;

import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.shared.enums.StatutApprenant;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Extension de {@link Utilisateur} avec les données spécifiques
 * à un formateur : spécialité, biographie, note globale.
 */
public class Formateur extends Utilisateur {

    private String specialite;
    private String biographie;
    private Double noteGlobale;  // 0.0 à 5.0

    /** Constructeur de reconstitution JPA. */
    public Formateur(UUID id, String prenom, String nom, String email,
                     String motDePasseHache, StatutApprenant statut,
                     int tentativesEchouees, LocalDateTime bloqueJusquAu,
                     LocalDateTime derniereConnexion, boolean emailVerifie,
                     String tokenVerif, LocalDateTime tokenVerificationEmailExpireAt, String telephone,
                     LocalDateTime createdAt, LocalDateTime updatedAt,
                     String specialite, String biographie, Double noteGlobale) {
        super(id, prenom, nom, email, motDePasseHache, Role.FORMATEUR, statut,
              tentativesEchouees, bloqueJusquAu, derniereConnexion, emailVerifie,
              tokenVerif, tokenVerificationEmailExpireAt, telephone, createdAt, updatedAt);
        this.specialite  = specialite;
        this.biographie  = biographie;
        this.noteGlobale = noteGlobale;
    }

    public void mettreAJourBio(String specialite, String biographie) {
        this.specialite = specialite;
        this.biographie = biographie;
        markUpdated();
    }

    public void mettreAJourNote(double note) {
        if (note < 0 || note > 5) throw new IllegalArgumentException("Note entre 0 et 5");
        this.noteGlobale = note;
        markUpdated();
    }

    public String getSpecialite()  { return specialite; }
    public String getBiographie()  { return biographie; }
    public Double getNoteGlobale() { return noteGlobale; }
}
