#!/usr/bin/env bash
# =============================================================================
# MbemNova — s17_jpa_entities_mappers_manquants.sh
# JPA Entities manquantes + tous les Mappers absents
# Ne touche PAS aux entités existantes
# =============================================================================
set -euo pipefail

ROOT="${1:-.}"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_NC='\033[0m'
ok()  { echo -e "  ${C_GREEN}✓${C_NC}  $1"; }
sec() { echo -e "\n${C_BLUE}▶ $1${C_NC}"; }

mkdir -p "$P/infrastructure/persistence/entity"
mkdir -p "$P/infrastructure/persistence/mapper"
mkdir -p "$P/infrastructure/persistence/repository"
mkdir -p "$P/infrastructure/persistence/adapter"

# =============================================================================
# ENTITÉS JPA MANQUANTES
# =============================================================================
sec "JPA Entity — AvisCoursJpaEntity"
cat > "$P/infrastructure/persistence/entity/AvisCoursJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "avis_cours")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AvisCoursJpaEntity {

    @Id
    private UUID id;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(name = "apprenant_id", nullable = false)
    private UUID apprenantId;

    @Column(nullable = false)
    private int note;

    @Column(columnDefinition = "TEXT")
    private String commentaire;

    @Column(name = "est_verifie", nullable = false)
    private boolean estVerifie;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
JEOF
ok "AvisCoursJpaEntity"

sec "JPA Entity — ListeAttenteJpaEntity"
cat > "$P/infrastructure/persistence/entity/ListeAttenteJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "liste_attente")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ListeAttenteJpaEntity {

    @Id
    private UUID id;

    @Column(name = "apprenant_id", nullable = false)
    private UUID apprenantId;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(name = "session_id")
    private UUID sessionId;

    @Column(nullable = false, length = 20)
    private String statut; // EN_ATTENTE, NOTIFIE, INSCRIT, ANNULE

    @Column(name = "date_inscription", nullable = false)
    private LocalDateTime dateInscription;

    @Column(name = "date_notification")
    private LocalDateTime dateNotification;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
JEOF
ok "ListeAttenteJpaEntity"

sec "JPA Entity — CreneauJpaEntity"
cat > "$P/infrastructure/persistence/entity/CreneauJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "creneaux")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreneauJpaEntity {

    @Id
    private UUID id;

    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @Column(name = "jour_semaine", nullable = false, length = 10)
    private String jourSemaine;

    @Column(name = "heure_debut", nullable = false)
    private LocalTime heureDebut;

    @Column(name = "duree_minutes", nullable = false)
    private int dureeMinutes;

    @Column(name = "capacite_max", nullable = false)
    private int capaciteMax;

    @Column(name = "places_restantes", nullable = false)
    private int placesRestantes;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
JEOF
ok "CreneauJpaEntity"

sec "JPA Entity — MoratoireJpaEntity"
cat > "$P/infrastructure/persistence/entity/MoratoireJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "moratoires")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MoratoireJpaEntity {

    @Id
    private UUID id;

    @Column(name = "paiement_id", nullable = false)
    private UUID paiementId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String raison;

    @Column(name = "nouvelle_date", nullable = false)
    private LocalDate nouvelleDate;

    @Column(nullable = false, length = 20)
    private String statut; // EN_ATTENTE, ACCORDE, REFUSE

    @Column(name = "admin_id")
    private UUID adminId;

    @Column(name = "justification_refus", columnDefinition = "TEXT")
    private String justificationRefus;

    @Column(name = "date_decision")
    private LocalDateTime dateDecision;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
JEOF
ok "MoratoireJpaEntity"

sec "JPA Entity — ParrainageJpaEntity"
cat > "$P/infrastructure/persistence/entity/ParrainageJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "parrainages")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ParrainageJpaEntity {

    @Id
    private UUID id;

    @Column(name = "parrain_id", nullable = false)
    private UUID parrainId;

    @Column(name = "filleul_id")
    private UUID filleulId;

    @Column(name = "code_parrainage", nullable = false, length = 20, unique = true)
    private String codeParrainage;

    @Column(nullable = false, length = 20)
    private String statut; // EN_ATTENTE, ACTIF, RECOMPENSE_ACCORDEE

    @Column(name = "date_inscription")
    private LocalDateTime dateInscription;

    @Column(name = "date_activation")
    private LocalDateTime dateActivation;

    @Column(name = "xp_parrain_credite", nullable = false)
    private int xpParrainCredite;

    @Column(name = "xp_filleul_credite", nullable = false)
    private int xpFilleulCredite;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
JEOF
ok "ParrainageJpaEntity"

sec "JPA Entity — TirageAuSortJpaEntity + GagnantTirageJpaEntity"
cat > "$P/infrastructure/persistence/entity/TirageAuSortJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "tirages_au_sort")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TirageAuSortJpaEntity {

    @Id
    private UUID id;

    @Column(nullable = false, length = 7, unique = true)
    private String mois; // YYYY-MM

    @Column(name = "nb_participants", nullable = false)
    private int nbParticipants;

    @Column(name = "formation_prix", length = 200)
    private String formationPrix;

    @Column(name = "valeur_prix")
    private Long valeurPrix;

    @Column(name = "admin_id", nullable = false)
    private UUID adminId;

    @Column(name = "effectue_le", nullable = false)
    private LocalDateTime effectueLe;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
JEOF
ok "TirageAuSortJpaEntity"

cat > "$P/infrastructure/persistence/entity/GagnantTirageJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "gagnants_tirage")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class GagnantTirageJpaEntity {

    @Id
    private UUID id;

    @Column(name = "tirage_id", nullable = false)
    private UUID tirageId;

    @Column(name = "apprenant_id", nullable = false)
    private UUID apprenantId;

    @Column(nullable = false)
    private int rang; // 1 = principal, 2-3 = consolation

    @Column(name = "lot_description", length = 300)
    private String lotDescription;

    @Column(nullable = false)
    private boolean notifie;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
JEOF
ok "GagnantTirageJpaEntity"

# =============================================================================
# REPOSITORIES JPA MANQUANTS
# =============================================================================
sec "Repositories JPA manquants"

cat > "$P/infrastructure/persistence/repository/AvisCoursJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AvisCoursJpaRepository extends JpaRepository<AvisCoursJpaEntity, UUID> {
    List<AvisCoursJpaEntity> findByCoursId(UUID coursId);
    Optional<AvisCoursJpaEntity> findByCoursIdAndApprenantId(UUID coursId, UUID apprenantId);
    boolean existsByCoursIdAndApprenantId(UUID coursId, UUID apprenantId);

    @Query("SELECT AVG(a.note) FROM AvisCoursJpaEntity a WHERE a.coursId = :coursId AND a.estVerifie = true")
    Optional<Double> calculerNoteMoyenne(UUID coursId);

    @Query("SELECT COUNT(a) FROM AvisCoursJpaEntity a WHERE a.coursId = :coursId AND a.estVerifie = true")
    int compterAvisVerifies(UUID coursId);
}
JEOF
ok "AvisCoursJpaRepository"

cat > "$P/infrastructure/persistence/repository/ListeAttenteJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ListeAttenteJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ListeAttenteJpaRepository extends JpaRepository<ListeAttenteJpaEntity, UUID> {
    Optional<ListeAttenteJpaEntity> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<ListeAttenteJpaEntity> findByCoursIdAndStatutOrderByDateInscriptionAsc(UUID coursId, String statut);
    boolean existsByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
}
JEOF
ok "ListeAttenteJpaRepository"

cat > "$P/infrastructure/persistence/repository/CreneauJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.CreneauJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface CreneauJpaRepository extends JpaRepository<CreneauJpaEntity, UUID> {
    List<CreneauJpaEntity> findBySessionId(UUID sessionId);
    List<CreneauJpaEntity> findBySessionIdAndPlacesRestantesGreaterThan(UUID sessionId, int minPlaces);
}
JEOF
ok "CreneauJpaRepository"

cat > "$P/infrastructure/persistence/repository/MoratoireJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.MoratoireJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MoratoireJpaRepository extends JpaRepository<MoratoireJpaEntity, UUID> {
    List<MoratoireJpaEntity> findByStatut(String statut);
    Optional<MoratoireJpaEntity> findByPaiementIdAndStatut(UUID paiementId, String statut);
    List<MoratoireJpaEntity> findByPaiementId(UUID paiementId);
    boolean existsByPaiementIdAndStatut(UUID paiementId, String statut);
}
JEOF
ok "MoratoireJpaRepository"

cat > "$P/infrastructure/persistence/repository/ParrainageJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ParrainageJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ParrainageJpaRepository extends JpaRepository<ParrainageJpaEntity, UUID> {
    Optional<ParrainageJpaEntity> findByCodeParrainage(String code);
    List<ParrainageJpaEntity> findByParrainId(UUID parrainId);
    Optional<ParrainageJpaEntity> findByFilleulId(UUID filleulId);
    long countByParrainIdAndStatut(UUID parrainId, String statut);
}
JEOF
ok "ParrainageJpaRepository"

cat > "$P/infrastructure/persistence/repository/TirageAuSortJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.TirageAuSortJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.entity.GagnantTirageJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TirageAuSortJpaRepository extends JpaRepository<TirageAuSortJpaEntity, UUID> {
    boolean existsByMois(String mois);
    Optional<TirageAuSortJpaEntity> findByMois(String mois);
}
JEOF
ok "TirageAuSortJpaRepository"

cat > "$P/infrastructure/persistence/repository/GagnantTirageJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.GagnantTirageJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface GagnantTirageJpaRepository extends JpaRepository<GagnantTirageJpaEntity, UUID> {
    List<GagnantTirageJpaEntity> findByTirageIdOrderByRangAsc(UUID tirageId);
}
JEOF
ok "GagnantTirageJpaRepository"

# =============================================================================
# MAPPERS JPA MANQUANTS
# =============================================================================
sec "Mappers JPA — tous les manquants"

cat > "$P/infrastructure/persistence/mapper/CoursJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface CoursJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Cours toDomain(CoursJpaEntity entity);

    CoursJpaEntity toEntity(Cours domain);
}
JEOF
ok "CoursJpaMapper"

cat > "$P/infrastructure/persistence/mapper/ProgressionJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ProgressionJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface ProgressionJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Progression toDomain(ProgressionJpaEntity entity);

    ProgressionJpaEntity toEntity(Progression domain);
}
JEOF
ok "ProgressionJpaMapper"

cat > "$P/infrastructure/persistence/mapper/PaiementJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.infrastructure.persistence.entity.PaiementJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface PaiementJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Paiement toDomain(PaiementJpaEntity entity);

    PaiementJpaEntity toEntity(Paiement domain);
}
JEOF
ok "PaiementJpaMapper"

cat > "$P/infrastructure/persistence/mapper/TrancheJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.paiement.Tranche;
import com.mbem.mbemlevel.infrastructure.persistence.entity.TrancheJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface TrancheJpaMapper {
    Tranche toDomain(TrancheJpaEntity entity);
    TrancheJpaEntity toEntity(Tranche domain);
}
JEOF
ok "TrancheJpaMapper"

cat > "$P/infrastructure/persistence/mapper/MoratoireJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.paiement.Moratoire;
import com.mbem.mbemlevel.infrastructure.persistence.entity.MoratoireJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface MoratoireJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Moratoire toDomain(MoratoireJpaEntity entity);

    MoratoireJpaEntity toEntity(Moratoire domain);
}
JEOF
ok "MoratoireJpaMapper"

cat > "$P/infrastructure/persistence/mapper/SessionJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.session.Session;
import com.mbem.mbemlevel.infrastructure.persistence.entity.SessionJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface SessionJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Session toDomain(SessionJpaEntity entity);

    SessionJpaEntity toEntity(Session domain);
}
JEOF
ok "SessionJpaMapper"

cat > "$P/infrastructure/persistence/mapper/DevoirJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.session.Devoir;
import com.mbem.mbemlevel.infrastructure.persistence.entity.DevoirJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface DevoirJpaMapper {
    Devoir toDomain(DevoirJpaEntity entity);
    DevoirJpaEntity toEntity(Devoir domain);
}
JEOF
ok "DevoirJpaMapper"

cat > "$P/infrastructure/persistence/mapper/RenduJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.session.Rendu;
import com.mbem.mbemlevel.infrastructure.persistence.entity.RenduJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface RenduJpaMapper {
    Rendu toDomain(RenduJpaEntity entity);
    RenduJpaEntity toEntity(Rendu domain);
}
JEOF
ok "RenduJpaMapper"

cat > "$P/infrastructure/persistence/mapper/CertificatJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.certificat.Certificat;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CertificatJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface CertificatJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    Certificat toDomain(CertificatJpaEntity entity);

    CertificatJpaEntity toEntity(Certificat domain);
}
JEOF
ok "CertificatJpaMapper"

cat > "$P/infrastructure/persistence/mapper/MessageCommunauteJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.communaute.MessageCommunaute;
import com.mbem.mbemlevel.infrastructure.persistence.entity.MessageCommunauteJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface MessageCommunauteJpaMapper {
    @Mapping(target = "domainEvents", ignore = true)
    MessageCommunaute toDomain(MessageCommunauteJpaEntity entity);

    MessageCommunauteJpaEntity toEntity(MessageCommunaute domain);
}
JEOF
ok "MessageCommunauteJpaMapper"

cat > "$P/infrastructure/persistence/mapper/NotificationJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.notification.Notification;
import com.mbem.mbemlevel.infrastructure.persistence.entity.NotificationJpaEntity;
import org.mapstruct.*;

@Mapper(
    componentModel       = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface NotificationJpaMapper {
    Notification toDomain(NotificationJpaEntity entity);
    NotificationJpaEntity toEntity(Notification domain);
}
JEOF
ok "NotificationJpaMapper"

cat > "$P/infrastructure/persistence/mapper/AvisCoursJpaMapper.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import com.mbem.mbemlevel.api.dto.response.AvisCoursResponse;
import org.mapstruct.*;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface AvisCoursJpaMapper {
    AvisCoursResponse toResponse(AvisCoursJpaEntity entity);
}
JEOF
ok "AvisCoursJpaMapper"

# =============================================================================
# PORT OUT MANQUANTS
# =============================================================================
sec "Ports Out manquants"

cat > "$P/application/port/out/MoratoireRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.paiement.Moratoire;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MoratoireRepository {
    Moratoire save(Moratoire moratoire);
    Optional<Moratoire> findById(UUID id);
    List<Moratoire> findEnAttente();
    Optional<Moratoire> findEnAttenteByPaiementId(UUID paiementId);
    boolean existsEnAttenteForPaiement(UUID paiementId);
}
JEOF
ok "MoratoireRepository (port out)"

cat > "$P/application/port/out/ParrainageRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.gamification.Parrainage;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ParrainageRepository {
    Parrainage save(Parrainage parrainage);
    Optional<Parrainage> findByCode(String code);
    Optional<Parrainage> findByFilleulId(UUID filleulId);
    List<Parrainage> findByParrainId(UUID parrainId);
    long countActifsByParrainId(UUID parrainId);
}
JEOF
ok "ParrainageRepository (port out)"

cat > "$P/application/port/out/AvisCoursRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AvisCoursRepository {
    AvisCoursJpaEntity save(AvisCoursJpaEntity avis);
    List<AvisCoursJpaEntity> findByCours(UUID coursId);
    Optional<AvisCoursJpaEntity> findByCoursAndApprenant(UUID coursId, UUID apprenantId);
    boolean existsByCoursAndApprenant(UUID coursId, UUID apprenantId);
    double calculerNoteMoyenne(UUID coursId);
    int compterAvisVerifies(UUID coursId);
}
JEOF
ok "AvisCoursRepository (port out)"

cat > "$P/application/port/out/ListeAttenteRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ListeAttenteJpaEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ListeAttenteRepository {
    ListeAttenteJpaEntity save(ListeAttenteJpaEntity entry);
    Optional<ListeAttenteJpaEntity> findByApprenantAndCours(UUID apprenantId, UUID coursId);
    List<ListeAttenteJpaEntity> findEnAttenteForCours(UUID coursId);
    boolean existsByApprenantAndCours(UUID apprenantId, UUID coursId);
}
JEOF
ok "ListeAttenteRepository (port out)"

echo -e "\n${C_GREEN}✅  Entités JPA, Repositories et Mappers générés${C_NC}"
echo "   Entités    : AvisCours, ListeAttente, Creneau, Moratoire, Parrainage, TirageAuSort, GagnantTirage"
echo "   Repos JPA  : AvisCours, ListeAttente, Creneau, Moratoire, Parrainage, TirageAuSort, GagnantTirage"
echo "   Mappers    : Cours, Progression, Paiement, Tranche, Moratoire, Session, Devoir, Rendu, Certificat, MessageCommunaute, Notification, AvisCours"
echo "   Ports Out  : MoratoireRepository, ParrainageRepository, AvisCoursRepository, ListeAttenteRepository"
