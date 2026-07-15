// =============================================================================
// MbemNova — infrastructure/persistence/mapper/UtilisateurJpaMapper.java
//
// Mapper MapStruct : UtilisateurJpaEntity ↔ Utilisateur (domaine).
// @Mapper(componentModel="spring") : géré par Spring comme un @Component.
//
// POINT CRITIQUE : Pour reconstruire un Utilisateur depuis la JPA,
// on utilise le constructeur de reconstitution — PAS la factory method creer().
// La factory method publie ApprenantInscritEvent — à ne déclencher qu'une fois.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.user.Utilisateur;
import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import org.mapstruct.*;

/**
 * Mapper bidirectionnel {@link UtilisateurJpaEntity} ↔ {@link Utilisateur}.
 *
 * <h3>Stratégie de reconstitution</h3>
 * <p>La méthode {@code toDomain} appelle le constructeur de reconstitution
 * de {@link Utilisateur} pour ne pas déclencher les domain events.</p>
 *
 * <h3>Champs ignorés</h3>
 * <p>{@code domainEvents} n'existe pas en JPA (transient) — toujours ignoré.</p>
 */
@Mapper(
    componentModel        = "spring",
    unmappedTargetPolicy  = ReportingPolicy.WARN,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface UtilisateurJpaMapper {

    /**
     * Convertit une entité JPA en objet domaine.
     * Utilise le constructeur de reconstitution.
     */
String[] IGNORED_FIELDS = {
        "ville", "xpTotal", "streakJours", "rangPlateforme", "disponiblePourEmploi",
        "lienPortfolio", "lienCv", "lienLinkedin", "lienGithub", "bio",
        "codeParrainage", "parrainId", "specialite", "biographie", "noteGlobale",
        "niveauAcces", "createdAt", "updatedAt", "domainEvents"
    };

    default Utilisateur toDomain(UtilisateurJpaEntity entity) {
        if (entity == null) return null;
        if (entity.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.APPRENANT) {
            return new com.mbem.mbemlevel.domain.user.Apprenant(
                entity.getId(), entity.getPrenom(), entity.getNom(), entity.getEmail(),
                entity.getMotDePasseHache(), entity.getStatut(),
                entity.getTentativesEchouees(),
                entity.getBloqueJusquAu(), entity.getDerniereConnexion(),
                entity.isEmailVerifie(), entity.getTokenVerificationEmail(),
                entity.getTokenVerificationEmailExpireAt(), entity.getTelephone(),
                entity.getCreatedAt(), entity.getUpdatedAt(),
                entity.getXpTotal(),
                entity.getStreakJours(),
                entity.getRangPlateforme(),
                entity.isDisponiblePourEmploi()
            );
        }
        return new Utilisateur(
            entity.getId(), entity.getPrenom(), entity.getNom(), entity.getEmail(),
            entity.getMotDePasseHache(), entity.getRole(), entity.getStatut(),
            entity.getTentativesEchouees(),
            entity.getBloqueJusquAu(), entity.getDerniereConnexion(),
            entity.isEmailVerifie(), entity.getTokenVerificationEmail(),
            entity.getTokenVerificationEmailExpireAt(), entity.getTelephone(),
            entity.getCreatedAt(), entity.getUpdatedAt()
        );
    }

    /**
     * Convertit un objet domaine en entité JPA pour l'insertion.
     */
    UtilisateurJpaEntity toJpaEntity(Utilisateur utilisateur);

    /**
     * Met à jour une entité JPA existante depuis l'objet domaine.
     * Pour les UPDATE : préserve l'état Hibernate (version, lazy collections…).
     *
     * @param source Domaine (source)
     * @param target Entité JPA attachée à la session Hibernate (modifiée en place)
     */
    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateJpaEntity(Utilisateur source, @MappingTarget UtilisateurJpaEntity target);
}
