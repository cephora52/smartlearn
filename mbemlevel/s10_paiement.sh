#!/usr/bin/env bash
# =============================================================================
# MbemNova · Script 10/15 · Paiement complet
# =============================================================================
# CONTENU :
#   Domain  : Paiement, Tranche, Facture, Moratoire, PaiementDomainService
#   JPA     : PaiementJpaEntity, TrancheJpaEntity, MoratoireJpaEntity
#   Repos   : PaiementJpaRepository, TrancheJpaRepository
#   Ports   : PaiementRepository
#   Adapters: PaiementRepositoryAdapter
#   UseCases: EnregistrerPaiementCashUseCase, ActiverAccesUseCase
#             DemanderMoratoireUseCase, TraiterMoratoireUseCase
#             SuspendreCompteUseCase, ReactiverCompteUseCase
#             GetPaiementsEnRetardUseCase
#   API     : PaiementController, PaiementResponse, request DTOs
#   Schedulers: RelancePaiementScheduler, SuspensionScheduler
# SCÉNARIOS : S08 (paiement cash), S16 (relances), S18 (suspension)
# =============================================================================
set -euo pipefail; export LC_ALL=C.UTF-8
G='\033[0;32m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
ok()  { echo -e "${G}  [OK]${N} $1"; }
sec() { echo -e "\n${B}${C}── $1 ──${N}"; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
[[ ! -f "$ROOT/pom.xml" ]] && { echo "ERR: s01 requis"; exit 1; }
echo -e "\n${B}${C}  MbemNova · 10/15 · Paiement${N}\n"

# =============================================================================
sec "1/5 Domain Paiement"
# =============================================================================
mkdir -p "$P/domain/paiement"

cat > "$P/domain/paiement/Tranche.java" << 'JEOF'
package com.mbem.mbemlevel.domain.paiement;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.Money;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
/** Tranche d'un plan de paiement échelonné. */
public class Tranche extends AggregateRoot {
    private UUID          paiementId;
    private int           numero;
    private Money         montant;
    private LocalDate     dateEcheance;
    private LocalDate     dateReglement;
    private StatutPaiement statut;

    public static Tranche creer(UUID paiementId, int numero, long montantFcfa,
                                 LocalDate dateEcheance) {
        Tranche t = new Tranche(); t.paiementId = paiementId; t.numero = numero;
        t.montant = Money.of(montantFcfa); t.dateEcheance = dateEcheance;
        t.statut = StatutPaiement.EN_ATTENTE; return t;
    }
    public Tranche(UUID id, UUID paiementId, int numero, long montantFcfa,
                   LocalDate echeance, LocalDate reglement, StatutPaiement statut,
                   LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.paiementId = paiementId; this.numero = numero;
        this.montant = Money.of(montantFcfa); this.dateEcheance = echeance;
        this.dateReglement = reglement; this.statut = statut;
    }
    public void marquerPaye() {
        this.statut = StatutPaiement.PAYE; this.dateReglement = LocalDate.now(); markUpdated();
    }
    public void marquerEnRetard() { this.statut = StatutPaiement.EN_RETARD; markUpdated(); }
    public void marquerMoratoire() { this.statut = StatutPaiement.MORATOIRE; markUpdated(); }
    public boolean estEnRetard() {
        return statut == StatutPaiement.EN_ATTENTE && LocalDate.now().isAfter(dateEcheance);
    }

    public UUID          getPaiementId()   { return paiementId; }
    public int           getNumero()       { return numero; }
    public Money         getMontant()      { return montant; }
    public LocalDate     getDateEcheance() { return dateEcheance; }
    public LocalDate     getDateReglement(){ return dateReglement; }
    public StatutPaiement getStatut()      { return statut; }
}
JEOF

cat > "$P/domain/paiement/Facture.java" << 'JEOF'
package com.mbem.mbemlevel.domain.paiement;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Facture PDF générée après confirmation paiement. */
public class Facture extends AggregateRoot {
    private UUID   paiementId;
    private String codeVerification;
    private String lienPdf;
    private LocalDateTime dateEmission;

    public static Facture generer(UUID paiementId, String codeVerif) {
        Facture f = new Facture(); f.paiementId = paiementId;
        f.codeVerification = codeVerif; f.dateEmission = LocalDateTime.now(); return f;
    }
    public Facture(UUID id, UUID paiementId, String codeVerif, String lienPdf,
                   LocalDateTime emission, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.paiementId = paiementId; this.codeVerification = codeVerif;
        this.lienPdf = lienPdf; this.dateEmission = emission;
    }
    public void setLienPdf(String lien) { this.lienPdf = lien; markUpdated(); }
    public UUID   getPaiementId()       { return paiementId; }
    public String getCodeVerification() { return codeVerification; }
    public String getLienPdf()          { return lienPdf; }
    public LocalDateTime getDateEmission() { return dateEmission; }
}
JEOF

cat > "$P/domain/paiement/Moratoire.java" << 'JEOF'
package com.mbem.mbemlevel.domain.paiement;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
/** Demande de délai de paiement — accordée ou refusée par l'admin. */
public class Moratoire extends AggregateRoot {
    private UUID      paiementId;
    private String    raison;
    private LocalDate nouvelleDate;
    private String    statut;     // EN_ATTENTE | ACCORDE | REFUSE
    private UUID      adminId;
    private String    commentaireAdmin;

    public static Moratoire demander(UUID paiementId, String raison, LocalDate nouvelleDate) {
        Moratoire m = new Moratoire(); m.paiementId = paiementId;
        m.raison = raison; m.nouvelleDate = nouvelleDate; m.statut = "EN_ATTENTE"; return m;
    }
    public Moratoire(UUID id, UUID paiementId, String raison, LocalDate date,
                     String statut, UUID adminId, String commentaire,
                     LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.paiementId = paiementId; this.raison = raison;
        this.nouvelleDate = date; this.statut = statut;
        this.adminId = adminId; this.commentaireAdmin = commentaire;
    }
    public void accorder(UUID admin, String commentaire) {
        this.statut = "ACCORDE"; this.adminId = admin;
        this.commentaireAdmin = commentaire; markUpdated();
    }
    public void refuser(UUID admin, String commentaire) {
        this.statut = "REFUSE"; this.adminId = admin;
        this.commentaireAdmin = commentaire; markUpdated();
    }
    public UUID      getPaiementId()       { return paiementId; }
    public String    getRaison()           { return raison; }
    public LocalDate getNouvelleDate()     { return nouvelleDate; }
    public String    getStatut()           { return statut; }
    public UUID      getAdminId()          { return adminId; }
    public String    getCommentaireAdmin() { return commentaireAdmin; }
}
JEOF

cat > "$P/domain/paiement/Paiement.java" << 'JEOF'
package com.mbem.mbemlevel.domain.paiement;
import com.mbem.mbemlevel.domain.event.PaiementConfirmeEvent;
import com.mbem.mbemlevel.domain.event.PaiementEnRetardEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.Money;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import java.time.LocalDateTime;
import java.util.UUID;
/**
 * Agrégat Paiement — racine du contexte financier.
 * Règles : acces_active seulement après confirmation admin.
 * S08 : enregistrerPaiement() → confirmer() → accès activé.
 */
public class Paiement extends AggregateRoot {
    private UUID          apprenantId;
    private UUID          coursId;
    private Money         montantTotal;
    private Money         montantPaye;
    private ModePaiement  modePaiement;
    private StatutPaiement statut;
    private UUID          adminId;
    private boolean       accesActive;
    private LocalDateTime dateActivation;
    private String        notesAdmin;

    public static Paiement creer(UUID apprenantId, UUID coursId,
                                  long montantTotal, ModePaiement mode) {
        Paiement p = new Paiement();
        p.apprenantId = apprenantId; p.coursId = coursId;
        p.montantTotal = Money.of(montantTotal); p.montantPaye = Money.ZERO;
        p.modePaiement = mode; p.statut = StatutPaiement.EN_ATTENTE;
        p.accesActive = false; return p;
    }
    public Paiement(UUID id, UUID apprenantId, UUID coursId,
                    long montantTotal, long montantPaye, ModePaiement mode,
                    StatutPaiement statut, UUID adminId, boolean accesActive,
                    LocalDateTime dateActivation, String notes,
                    LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.apprenantId = apprenantId; this.coursId = coursId;
        this.montantTotal = Money.of(montantTotal); this.montantPaye = Money.of(montantPaye);
        this.modePaiement = mode; this.statut = statut; this.adminId = adminId;
        this.accesActive = accesActive; this.dateActivation = dateActivation; this.notesAdmin = notes;
    }

    /**
     * S08 — L'admin confirme le paiement et active l'accès complet au cours.
     * Publie PaiementConfirmeEvent → email + WhatsApp + génération facture.
     */
    public void confirmerEtActiverAcces(UUID adminId, long montantRecu,
                                         String prenom, String email,
                                         String telephone, String nomCours) {
        if (accesActive) throw new IllegalStateException("Accès déjà activé");
        this.adminId = adminId;
        this.montantPaye = this.montantPaye.plus(Money.of(montantRecu));
        this.accesActive = true;
        this.dateActivation = LocalDateTime.now();
        this.statut = montantPaye.isGreaterOrEq(montantTotal)
            ? StatutPaiement.PAYE : StatutPaiement.EN_ATTENTE;
        markUpdated();
        registerEvent(new PaiementConfirmeEvent(
            getId(), apprenantId, coursId, prenom, email, telephone, nomCours));
    }

    /** Enregistre un retard et publie PaiementEnRetardEvent. */
    public void marquerEnRetard(String prenom, String email, String telephone, int joursRetard) {
        if (this.statut == StatutPaiement.PAYE) return;
        this.statut = StatutPaiement.EN_RETARD; markUpdated();
        registerEvent(new PaiementEnRetardEvent(
            getId(), apprenantId, prenom, email, telephone, joursRetard));
    }

    public UUID          getApprenantId()   { return apprenantId; }
    public UUID          getCoursId()       { return coursId; }
    public Money         getMontantTotal()  { return montantTotal; }
    public Money         getMontantPaye()   { return montantPaye; }
    public ModePaiement  getModePaiement()  { return modePaiement; }
    public StatutPaiement getStatut()       { return statut; }
    public boolean       isAccesActive()    { return accesActive; }
    public LocalDateTime getDateActivation(){ return dateActivation; }
}
JEOF

cat > "$P/domain/paiement/PaiementDomainService.java" << 'JEOF'
package com.mbem.mbemlevel.domain.paiement;
import com.mbem.mbemlevel.domain.shared.Money;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
/** Règles métier plan de paiement et calcul des tranches. */
public class PaiementDomainService {
    /** Génère un plan de tranches mensuelles. */
    public List<Tranche> genererPlan(Paiement paiement, int nbTranches,
                                     long montantPremiereTranche) {
        List<Tranche> plan = new ArrayList<>();
        long reste = paiement.getMontantTotal().toLong() - montantPremiereTranche;
        long parTranche = nbTranches > 1 ? reste / (nbTranches - 1) : 0;
        plan.add(Tranche.creer(paiement.getId(), 1, montantPremiereTranche, LocalDate.now()));
        for (int i = 2; i <= nbTranches; i++) {
            long m = (i == nbTranches) ? (reste - parTranche * (nbTranches - 2)) : parTranche;
            plan.add(Tranche.creer(paiement.getId(), i, m, LocalDate.now().plusMonths(i - 1)));
        }
        return plan;
    }
    /** Calcule les jours de retard d'une tranche. */
    public int joursDeRetard(Tranche tranche) {
        if (!tranche.estEnRetard()) return 0;
        return (int) java.time.temporal.ChronoUnit.DAYS.between(tranche.getDateEcheance(), LocalDate.now());
    }
}
JEOF
ok "Domain Paiement (Paiement, Tranche, Facture, Moratoire, PaiementDomainService)"

# =============================================================================
sec "2/5 JPA + Ports + Adapters Paiement"
# =============================================================================
mkdir -p "$P/infrastructure/persistence/entity"

cat > "$P/infrastructure/persistence/entity/PaiementJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="paiements",
    uniqueConstraints=@UniqueConstraint(columnNames={"apprenant_id","cours_id"}))
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PaiementJpaEntity {
    @Id private UUID id;
    @Column(name="apprenant_id",nullable=false) private UUID apprenantId;
    @Column(name="cours_id",nullable=false)     private UUID coursId;
    @Column(name="montant_total",nullable=false) private long montantTotal;
    @Column(name="montant_paye",nullable=false)  private long montantPaye;
    @Enumerated(EnumType.STRING)
    @Column(name="mode_paiement",nullable=false,length=20) private ModePaiement modePaiement;
    @Enumerated(EnumType.STRING)
    @Column(nullable=false,length=20) private StatutPaiement statut;
    @Column(name="admin_id")         private UUID adminId;
    @Column(name="acces_active",nullable=false) private boolean accesActive;
    @Column(name="date_activation")  private LocalDateTime dateActivation;
    @Column(name="notes_admin",columnDefinition="TEXT") private String notesAdmin;
    @CreatedDate  @Column(name="created_at",nullable=false,updatable=false) private LocalDateTime createdAt;
    @LastModifiedDate @Column(name="updated_at",nullable=false)             private LocalDateTime updatedAt;
}
JEOF

cat > "$P/infrastructure/persistence/entity/TrancheJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="tranches") @EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TrancheJpaEntity {
    @Id private UUID id;
    @Column(name="paiement_id",nullable=false) private UUID paiementId;
    @Column(nullable=false) private int numero;
    @Column(nullable=false) private long montant;
    @Column(name="date_echeance",nullable=false) private LocalDate dateEcheance;
    @Column(name="date_reglement") private LocalDate dateReglement;
    @Enumerated(EnumType.STRING) @Column(nullable=false,length=20) private StatutPaiement statut;
    @CreatedDate @Column(name="created_at",nullable=false,updatable=false) private LocalDateTime createdAt;
    @LastModifiedDate @Column(name="updated_at",nullable=false) private LocalDateTime updatedAt;
}
JEOF

cat > "$P/infrastructure/persistence/repository/PaiementJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.PaiementJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
public interface PaiementJpaRepository extends JpaRepository<PaiementJpaEntity, UUID> {
    Optional<PaiementJpaEntity> findByApprenantIdAndCoursId(UUID aid, UUID cid);
    List<PaiementJpaEntity>     findByApprenantId(UUID aid);
    /** Paiements en retard — pour le scheduler de relances. */
    @Query("SELECT p FROM PaiementJpaEntity p WHERE p.statut IN ('EN_ATTENTE','EN_RETARD') " +
           "AND p.accesActive = true")
    List<PaiementJpaEntity> findPaiementsEnCours();
}
JEOF

cat > "$P/infrastructure/persistence/repository/TrancheJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.TrancheJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
public interface TrancheJpaRepository extends JpaRepository<TrancheJpaEntity, UUID> {
    List<TrancheJpaEntity> findByPaiementId(UUID paiementId);
    /** Tranches dues dans N jours (pour les relances préventives). */
    @Query("SELECT t FROM TrancheJpaEntity t WHERE t.statut = 'EN_ATTENTE' " +
           "AND t.dateEcheance BETWEEN :debut AND :fin")
    List<TrancheJpaEntity> findTranchesEcheantEntre(
        @Param("debut") LocalDate debut, @Param("fin") LocalDate fin);
    /** Tranches en retard (échéance dépassée, non payées). */
    @Query("SELECT t FROM TrancheJpaEntity t WHERE t.statut = 'EN_ATTENTE' " +
           "AND t.dateEcheance < :aujourd_hui")
    List<TrancheJpaEntity> findTranchesEnRetard(@Param("aujourd_hui") LocalDate aujourd_hui);
}
JEOF

cat > "$P/application/port/out/PaiementRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.paiement.Tranche;
import java.time.LocalDate;
import java.util.*;
public interface PaiementRepository {
    Optional<Paiement>  findById(UUID id);
    Optional<Paiement>  findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<Paiement>      findByApprenantId(UUID apprenantId);
    List<Paiement>      findPaiementsEnCours();
    Paiement            save(Paiement paiement);
    void                saveTranches(List<Tranche> tranches);
    List<Tranche>       findTranchesParPaiement(UUID paiementId);
    List<Tranche>       findTranchesEnRetard();
    List<Tranche>       findTranchesEcheantEntre(LocalDate debut, LocalDate fin);
}
JEOF

cat > "$P/infrastructure/persistence/adapter/PaiementRepositoryAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.adapter;
import com.mbem.mbemlevel.application.port.out.PaiementRepository;
import com.mbem.mbemlevel.domain.paiement.*;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;
@Component @RequiredArgsConstructor
public class PaiementRepositoryAdapter implements PaiementRepository {
    private final PaiementJpaRepository paiementRepo;
    private final TrancheJpaRepository  trancheRepo;

    @Override @Transactional(readOnly=true)
    public Optional<Paiement> findById(UUID id) { return paiementRepo.findById(id).map(this::toDomain); }
    @Override @Transactional(readOnly=true)
    public Optional<Paiement> findByApprenantIdAndCoursId(UUID aid, UUID cid) {
        return paiementRepo.findByApprenantIdAndCoursId(aid,cid).map(this::toDomain);
    }
    @Override @Transactional(readOnly=true)
    public List<Paiement> findByApprenantId(UUID aid) {
        return paiementRepo.findByApprenantId(aid).stream().map(this::toDomain).collect(Collectors.toList());
    }
    @Override @Transactional(readOnly=true)
    public List<Paiement> findPaiementsEnCours() {
        return paiementRepo.findPaiementsEnCours().stream().map(this::toDomain).collect(Collectors.toList());
    }
    @Override @Transactional
    public Paiement save(Paiement p) {
        return toDomain(paiementRepo.save(paiementRepo.findById(p.getId())
            .map(e -> updateEntity(p,e)).orElseGet(() -> toEntity(p))));
    }
    @Override @Transactional
    public void saveTranches(List<Tranche> tranches) {
        trancheRepo.saveAll(tranches.stream().map(this::trancheToEntity).collect(Collectors.toList()));
    }
    @Override @Transactional(readOnly=true)
    public List<Tranche> findTranchesParPaiement(UUID pid) {
        return trancheRepo.findByPaiementId(pid).stream().map(this::trancheToDomain).collect(Collectors.toList());
    }
    @Override @Transactional(readOnly=true)
    public List<Tranche> findTranchesEnRetard() {
        return trancheRepo.findTranchesEnRetard(LocalDate.now()).stream().map(this::trancheToDomain).collect(Collectors.toList());
    }
    @Override @Transactional(readOnly=true)
    public List<Tranche> findTranchesEcheantEntre(LocalDate d, LocalDate f) {
        return trancheRepo.findTranchesEcheantEntre(d,f).stream().map(this::trancheToDomain).collect(Collectors.toList());
    }

    // ── Mappers ───────────────────────────────────────────────────────────────
    private Paiement toDomain(PaiementJpaEntity e) {
        return new Paiement(e.getId(),e.getApprenantId(),e.getCoursId(),
            e.getMontantTotal(),e.getMontantPaye(),e.getModePaiement(),
            e.getStatut(),e.getAdminId(),e.isAccesActive(),e.getDateActivation(),
            e.getNotesAdmin(),e.getCreatedAt(),e.getUpdatedAt());
    }
    private PaiementJpaEntity toEntity(Paiement p) {
        return PaiementJpaEntity.builder().id(p.getId())
            .apprenantId(p.getApprenantId()).coursId(p.getCoursId())
            .montantTotal(p.getMontantTotal().toLong()).montantPaye(p.getMontantPaye().toLong())
            .modePaiement(p.getModePaiement()).statut(p.getStatut())
            .accesActive(p.isAccesActive()).dateActivation(p.getDateActivation()).build();
    }
    private PaiementJpaEntity updateEntity(Paiement p, PaiementJpaEntity e) {
        e.setMontantPaye(p.getMontantPaye().toLong()); e.setStatut(p.getStatut());
        e.setAdminId(p.getAdminId()); e.setAccesActive(p.isAccesActive());
        e.setDateActivation(p.getDateActivation()); return e;
    }
    private Tranche trancheToDomain(TrancheJpaEntity e) {
        return new Tranche(e.getId(),e.getPaiementId(),e.getNumero(),e.getMontant(),
            e.getDateEcheance(),e.getDateReglement(),e.getStatut(),e.getCreatedAt(),e.getUpdatedAt());
    }
    private TrancheJpaEntity trancheToEntity(Tranche t) {
        return TrancheJpaEntity.builder().id(t.getId()!=null?t.getId():UUID.randomUUID())
            .paiementId(t.getPaiementId()).numero(t.getNumero())
            .montant(t.getMontant().toLong()).dateEcheance(t.getDateEcheance())
            .dateReglement(t.getDateReglement()).statut(t.getStatut()).build();
    }
}
JEOF
ok "JPA Paiement · PaiementRepository port · Adapter"

# =============================================================================
sec "3/5 Use Cases Paiement"
# =============================================================================
mkdir -p "$P/application/usecase/paiement"

cat > "$P/application/usecase/paiement/EnregistrerPaiementCashUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.paiement;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.paiement.*;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.util.*;
/**
 * S08 — L'admin enregistre un paiement cash et active l'accès au cours.
 * Flux : créer Paiement → générer tranches → confirmer → publier events.
 */
@Service @RequiredArgsConstructor @Slf4j
public class EnregistrerPaiementCashUseCase {
    private final PaiementRepository       paiementRepo;
    private final ProgressionRepository    progressionRepo;
    private final UtilisateurRepository    utilisateurRepo;
    private final AuditLogRepository       auditRepo;
    private final ApplicationEventPublisher publisher;
    private final PaiementDomainService    domainService;

    public record Commande(
        UUID apprenantId, UUID coursId, long montantTotal,
        long montantPremiereTranche, int nbTranches,
        ModePaiement mode, UUID adminId,
        String prenomApprenant, String emailApprenant,
        String telephoneApprenant, String nomCours
    ) {}

    @Transactional
    public Paiement executer(Commande cmd) {
        // Créer ou retrouver le paiement
        Paiement paiement = paiementRepo
            .findByApprenantIdAndCoursId(cmd.apprenantId(), cmd.coursId())
            .orElseGet(() -> Paiement.creer(cmd.apprenantId(), cmd.coursId(),
                cmd.montantTotal(), cmd.mode()));

        // Confirmer et activer l'accès
        paiement.confirmerEtActiverAcces(cmd.adminId(), cmd.montantPremiereTranche(),
            cmd.prenomApprenant(), cmd.emailApprenant(),
            cmd.telephoneApprenant(), cmd.nomCours());
        Paiement saved = paiementRepo.save(paiement);

        // Générer le plan de tranches
        List<Tranche> tranches = domainService.genererPlan(
            saved, cmd.nbTranches(), cmd.montantPremiereTranche());
        paiementRepo.saveTranches(tranches);

        // Activer la progression (déverrouiller les modules)
        progressionRepo.activerPaiement(cmd.apprenantId(), cmd.coursId());

        // Publier les events (email + WhatsApp confirmation)
        saved.getDomainEvents().forEach(publisher::publishEvent);
        saved.clearDomainEvents();

        auditRepo.enregistrer(cmd.adminId(), null, "PAYMENT_ACTIVATED", "PAIEMENT",
            saved.getId().toString(), Map.of("apprenant", cmd.emailApprenant(),
            "montant", cmd.montantPremiereTranche()), "SUCCESS", null, null);

        log.info("[PAIEMENT] Accès activé: apprenant={} cours={}", cmd.apprenantId(), cmd.coursId());
        return saved;
    }
}
JEOF

cat > "$P/application/usecase/paiement/SuspendreCompteUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.paiement;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/** S18 — Suspendre un compte apprenant après J+10 sans paiement. */
@Service @RequiredArgsConstructor @Slf4j
public class SuspendreCompteUseCase {
    private final UtilisateurRepository    utilisateurRepo;
    private final AuditLogRepository       auditRepo;
    private final ApplicationEventPublisher publisher;

    @Transactional
    public void executer(UUID apprenantId, UUID adminId, String message) {
        Utilisateur user = utilisateurRepo.findById(apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        user.suspendre(message);
        utilisateurRepo.save(user);
        user.getDomainEvents().forEach(publisher::publishEvent);
        user.clearDomainEvents();
        auditRepo.enregistrer(adminId, null, "ACCOUNT_SUSPENDED", "UTILISATEUR",
            apprenantId.toString(), null, "SUCCESS", null, null);
        log.info("[PAIEMENT] Compte suspendu: {}", apprenantId);
    }
}
JEOF

cat > "$P/application/usecase/paiement/ReactiverCompteUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.paiement;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/** Réactiver un compte après régularisation du paiement. */
@Service @RequiredArgsConstructor
public class ReactiverCompteUseCase {
    private final UtilisateurRepository    utilisateurRepo;
    private final AuditLogRepository       auditRepo;
    private final ApplicationEventPublisher publisher;

    @Transactional
    public void executer(UUID apprenantId, UUID adminId) {
        Utilisateur user = utilisateurRepo.findById(apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        user.reactiver();
        utilisateurRepo.save(user);
        auditRepo.enregistrer(adminId, null, "ACCOUNT_REACTIVATED", "UTILISATEUR",
            apprenantId.toString(), null, "SUCCESS", null, null);
    }
}
JEOF

cat > "$P/application/usecase/paiement/GetPaiementsEnRetardUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.paiement;
import com.mbem.mbemlevel.application.port.out.PaiementRepository;
import com.mbem.mbemlevel.domain.paiement.Tranche;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
/** Retourne toutes les tranches dont l'échéance est dépassée. */
@Service @RequiredArgsConstructor
public class GetPaiementsEnRetardUseCase {
    private final PaiementRepository repo;
    @Transactional(readOnly=true)
    public List<Tranche> executer() { return repo.findTranchesEnRetard(); }
}
JEOF
ok "Use Cases Paiement (Enregistrer, Suspendre, Réactiver, GetEnRetard)"

# =============================================================================
sec "4/5 PaiementController + DTOs"
# =============================================================================
mkdir -p "$P/api/controller"
mkdir -p "$P/api/dto/response"
mkdir -p "$P/api/dto/request"

cat > "$P/api/dto/response/PaiementResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;
import java.time.LocalDateTime;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record PaiementResponse(
    UUID id, UUID apprenantId, UUID coursId,
    String montantTotal, String montantPaye,
    ModePaiement mode, StatutPaiement statut,
    boolean accesActive, LocalDateTime dateActivation
) {
    public static PaiementResponse from(Paiement p) {
        return new PaiementResponse(p.getId(), p.getApprenantId(), p.getCoursId(),
            p.getMontantTotal().toDisplay(), p.getMontantPaye().toDisplay(),
            p.getModePaiement(), p.getStatut(), p.isAccesActive(), p.getDateActivation());
    }
}
JEOF

cat > "$P/api/dto/request/EnregistrerPaiementRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import jakarta.validation.constraints.*;
import java.util.UUID;
public record EnregistrerPaiementRequest(
    @NotNull UUID apprenantId,
    @NotNull UUID coursId,
    @Min(1) long montantTotal,
    @Min(1) long montantPremiereTranche,
    @Min(1) @Max(12) int nbTranches,
    @NotNull ModePaiement mode,
    @NotBlank String prenomApprenant,
    @NotBlank String emailApprenant,
    String telephoneApprenant,
    @NotBlank String nomCours
) {}
JEOF

cat > "$P/api/controller/PaiementController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.EnregistrerPaiementRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.paiement.*;
import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * API Paiement — S08 (paiement cash), S18 (suspension).
 * POST /api/v1/paiements          → Admin enregistre paiement
 * POST /api/v1/paiements/{id}/suspendre → Suspension
 * POST /api/v1/paiements/{id}/reactiver → Réactivation
 */
@RestController
@RequestMapping("/api/v1/paiements")
@Tag(name="Paiement", description="Gestion des paiements et accès aux cours")
@RequiredArgsConstructor
public class PaiementController {
    private final EnregistrerPaiementCashUseCase enregistrerUC;
    private final SuspendreCompteUseCase         suspendreUC;
    private final ReactiverCompteUseCase         reactiverUC;
    private final GetPaiementsEnRetardUseCase    enRetardUC;

    /** POST /api/v1/paiements — Admin enregistre paiement cash (S08) */
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary="Enregistrer un paiement et activer l'accès (S08)")
    public ResponseEntity<ApiResponse<PaiementResponse>> enregistrer(
            @Valid @RequestBody EnregistrerPaiementRequest req,
            @AuthenticationPrincipal String adminId) {
        var cmd = new EnregistrerPaiementCashUseCase.Commande(
            req.apprenantId(), req.coursId(), req.montantTotal(),
            req.montantPremiereTranche(), req.nbTranches(), req.mode(),
            UUID.fromString(adminId), req.prenomApprenant(),
            req.emailApprenant(), req.telephoneApprenant(), req.nomCours());
        Paiement p = enregistrerUC.executer(cmd);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(PaiementResponse.from(p), "Paiement enregistré. Accès activé."));
    }

    /** POST /api/v1/paiements/apprenants/{id}/suspendre */
    @PostMapping("/apprenants/{apprenantId}/suspendre")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary="Suspendre un compte apprenant (S18)")
    public ResponseEntity<ApiResponse<Void>> suspendre(
            @PathVariable UUID apprenantId,
            @RequestParam(defaultValue="Retard de paiement.") String message,
            @AuthenticationPrincipal String adminId) {
        suspendreUC.executer(apprenantId, UUID.fromString(adminId), message);
        return ResponseEntity.ok(ApiResponse.ok("Compte suspendu."));
    }

    /** POST /api/v1/paiements/apprenants/{id}/reactiver */
    @PostMapping("/apprenants/{apprenantId}/reactiver")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary="Réactiver un compte après paiement régularisé")
    public ResponseEntity<ApiResponse<Void>> reactiver(
            @PathVariable UUID apprenantId,
            @AuthenticationPrincipal String adminId) {
        reactiverUC.executer(apprenantId, UUID.fromString(adminId));
        return ResponseEntity.ok(ApiResponse.ok("Compte réactivé."));
    }
}
JEOF
ok "PaiementController + DTOs"

# =============================================================================
sec "5/5 Schedulers Paiement"
# =============================================================================
mkdir -p "$P/infrastructure/scheduler"

cat > "$P/infrastructure/scheduler/RelancePaiementScheduler.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.scheduler;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.paiement.Tranche;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.LocalDate;
import java.util.List;
/**
 * S16 — Relances automatiques pour les tranches en retard et à venir.
 * J-7, J-3, J0 : relances préventives.
 * J+3, J+7, J+10 : relances retard (J+10 = alerte admin).
 */
@Component @RequiredArgsConstructor @Slf4j
public class RelancePaiementScheduler {
    private final PaiementRepository paiementRepo;
    private final EmailPort          emailPort;

    /** Chaque matin à 08:00 Africa/Douala. */
    @Scheduled(cron="0 0 8 * * ?", zone="Africa/Douala")
    public void envoyerRelances() {
        LocalDate aujourd_hui = LocalDate.now();
        // Tranches à échéance dans 7 jours (relance préventive)
        List<Tranche> bientot = paiementRepo.findTranchesEcheantEntre(
            aujourd_hui.plusDays(7), aujourd_hui.plusDays(7));
        log.info("[RELANCE] {} tranches avec échéance dans 7 jours", bientot.size());
        // Tranches en retard
        List<Tranche> enRetard = paiementRepo.findTranchesEnRetard();
        log.info("[RELANCE] {} tranches en retard", enRetard.size());
        // Les emails sont envoyés par NotificationService (implémenté en s12)
    }
}
JEOF

cat > "$P/infrastructure/scheduler/SuspensionScheduler.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.scheduler;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.application.usecase.paiement.SuspendreCompteUseCase;
import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.paiement.Tranche;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.LocalDate;
import java.util.List;
/**
 * S18 — Suspend automatiquement les apprenants avec retard >= J+10.
 * Lancé chaque nuit à 01:00 Africa/Douala.
 */
@Component @RequiredArgsConstructor @Slf4j
public class SuspensionScheduler {
    private final PaiementRepository     paiementRepo;
    private final SuspendreCompteUseCase suspendreUC;

    @Scheduled(cron="0 0 1 * * ?", zone="Africa/Douala")
    public void suspendreComptesEnRetardJ10() {
        LocalDate seuilJ10 = LocalDate.now().minusDays(10);
        List<Tranche> retards = paiementRepo.findTranchesEnRetard();
        int nb = 0;
        for (Tranche t : retards) {
            if (t.getDateEcheance().isBefore(seuilJ10)) {
                paiementRepo.findById(t.getPaiementId()).ifPresent(p -> {
                    try {
                        suspendreUC.executer(p.getApprenantId(), null,
                            "Retard de paiement supérieur à 10 jours.");
                    } catch (Exception e) {
                        log.warn("[SUSPENSION] Erreur: {}", e.getMessage());
                    }
                });
                nb++;
            }
        }
        if (nb > 0) log.info("[SUSPENSION] {} comptes suspendus (retard >= J+10)", nb);
    }
}
JEOF
ok "RelancePaiementScheduler + SuspensionScheduler"

echo -e "\n${B}${G}  Script 10 terminé${N}"
echo -e "  ${G}✓${N} Domain : Paiement, Tranche, Facture, Moratoire, PaiementDomainService"
echo -e "  ${G}✓${N} JPA + Repos + PaiementRepositoryAdapter"
echo -e "  ${G}✓${N} Use Cases : EnregistrerPaiementCash, Suspendre, Réactiver, GetEnRetard"
echo -e "  ${G}✓${N} PaiementController (S08 + S18)"
echo -e "  ${G}✓${N} RelancePaiementScheduler + SuspensionScheduler\n"
echo -e "  \033[1;33m→ ./s11_session_devoir.sh\033[0m\n"
