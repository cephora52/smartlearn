// MbemNova — domain/user/Admin.java
package com.mbem.mbemlevel.domain.user;

import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.shared.enums.StatutApprenant;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Extension de {@link Utilisateur} pour les administrateurs.
 * Niveau d'accès : STANDARD ou SUPER.
 */
public class Admin extends Utilisateur {

    /** STANDARD : gestion opérationnelle. SUPER : gestion technique complète. */
    private String niveauAcces;

    public Admin(UUID id, String prenom, String nom, String email,
                 String motDePasseHache, Role role, StatutApprenant statut,
                 int tentatives, LocalDateTime bloque, LocalDateTime derniereCo,
                 boolean emailVerifie, String tokenVerif, LocalDateTime tokenVerificationEmailExpireAt, String telephone,
                 LocalDateTime createdAt, LocalDateTime updatedAt, String niveauAcces) {
        super(id, prenom, nom, email, motDePasseHache, role, statut,
              tentatives, bloque, derniereCo, emailVerifie, tokenVerif,
              tokenVerificationEmailExpireAt, telephone, createdAt, updatedAt);
        this.niveauAcces = niveauAcces;
    }

    public String getNiveauAcces() { return niveauAcces; }
}
