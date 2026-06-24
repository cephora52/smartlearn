// =============================================================================
// MbemNova — application/port/out/UtilisateurRepository.java
//
// Port sortant : contrat de persistance des utilisateurs.
// L'implémentation est dans UtilisateurRepositoryAdapter (infrastructure).
// Le domaine ne connaît pas JPA — il ne connaît que ce contrat.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.Query;

import com.mbem.mbemlevel.domain.cours.infrastructure.persistence.entity.UtilisateurJpaEntity;
import com.mbem.mbemlevel.domain.user.Utilisateur;

import io.lettuce.core.dynamic.annotation.Param;

/**
 * Port sortant (secondary port) pour la persistance des utilisateurs.
 *
 * <p>Toutes les méthodes sont en lecture pessimiste ou écriture transactionnelle.
 * La gestion des transactions (@Transactional) appartient aux adaptateurs.</p>
 */
public interface UtilisateurRepository {

    /** Recherche par UUID — retourne empty si inexistant. */
    Optional<Utilisateur> findById(UUID id);

    /**
     * Recherche par email (insensible à la casse).
     * Appelé à chaque connexion — index unique sur LOWER(email) en BDD.
     */
    Optional<Utilisateur> findByEmail(String email);

    /**
     * Vérifie l'existence d'un email sans charger l'objet complet.
     * Plus performant que findByEmail pour la vérification à l'inscription.
     */
    boolean existsByEmail(String email);

    /**
     * Persiste un utilisateur (INSERT ou UPDATE selon existence de l'ID).
     * Retourne l'entité sauvegardée (avec les champs auto-générés).
     */
    Utilisateur save(Utilisateur utilisateur);

    /** Liste des apprenants disponibles pour l'emploi (vitrine Talents). */
    List<Utilisateur> findApprenantsDisponibles();


      Optional<Utilisateur> findByTokenVerificationEmail(String token);

       List<Utilisateur> findAll(); 


 
}
