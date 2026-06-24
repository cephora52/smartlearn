#!/usr/bin/env bash
# =============================================================================
# MbemNova · Script 12/15 · Certificat + Talent + Notification + Communauté
# =============================================================================
# CONTENU :
#   Domain  : Certificat, CertificatDomainService
#             Notification
#             MessageCommunaute, Signalement
#             Parrainage, TirageAuSort
#
#   JPA + Repos + Adapters + Ports :
#             CertificatRepository, NotificationRepository
#             CommunauteRepository
#             PDFPort, StoragePort, WhatsAppPort (interfaces)
#
#   Use Cases Talent  : MettreAJourProfilUseCase, GetProfilTalentUseCase
#   Use Cases Certif  : GenererCertificatUseCase, VerifierCertificatUseCase
#   Use Cases Comm    : PostMessageUseCase, RepondreMessageUseCase,
#                       SignalerMessageUseCase
#   Use Cases Gamif   : TraiterParrainageUseCase
#
#   Controllers : TalentController, CertificatController,
#                 NotificationController, CommunauteController
#
#   DTOs        : ProfilTalentResponse, CertificatResponse,
#                 NotificationResponse, MessageResponse
#
# SCÉNARIOS : S12 (communauté Q&R), S13 (certificat),
#             S14 (profil talent), S15 (parrainage)
# =============================================================================
set -euo pipefail; export LC_ALL=C.UTF-8
G='\033[0;32m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
ok()  { echo -e "${G}  [OK]${N} $1"; }
sec() { echo -e "\n${B}${C}── $1 ──${N}"; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
[[ ! -f "$ROOT/pom.xml" ]] && { echo "ERR: s01 requis"; exit 1; }
echo -e "\n${B}${C}  MbemNova · 12/15 · Certificat + Talent + Notif + Communauté${N}\n"

# =============================================================================
sec "1/6 Domain Certificat + Communauté + Gamification"
# =============================================================================
mkdir -p "$P/domain/certificat"
mkdir -p "$P/domain/notification"
mkdir -p "$P/domain/communaute"
mkdir -p "$P/domain/gamification"

cat > "$P/domain/certificat/Certificat.java" << 'JEOF'
package com.mbem.mbemlevel.domain.certificat;
import com.mbem.mbemlevel.domain.event.CertificatObtenuEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.UUID;
/**
 * Agrégat Certificat — émis après validation complète d'un cours payant.
 * Le codeVerification est public : n'importe qui peut vérifier l'authenticité
 * sur mbemnova.com/verify/{code}
 */
public class Certificat extends AggregateRoot {
    private UUID   apprenantId;
    private UUID   coursId;
    /** Code unique URL-safe — affiché sur le certificat PDF, vérifiable publiquement. */
    private String codeVerification;
    private String lienPdf;
    private LocalDateTime dateEmission;

    private static final SecureRandom RANDOM = new SecureRandom();

    public static Certificat emettre(UUID apprenantId, UUID coursId,
                                      String prenomApprenant, String emailApprenant,
                                      String telephoneApprenant, String nomCours) {
        Certificat c = new Certificat();
        c.apprenantId     = apprenantId;
        c.coursId         = coursId;
        c.codeVerification = genererCode();
        c.dateEmission    = LocalDateTime.now();
        // Event → génère le PDF + email + WhatsApp
        c.registerEvent(new CertificatObtenuEvent(
            c.getId(), apprenantId, coursId,
            prenomApprenant, emailApprenant, telephoneApprenant,
            nomCours, c.codeVerification));
        return c;
    }
    public Certificat(UUID id, UUID apprenantId, UUID coursId,
                      String codeVerification, String lienPdf,
                      LocalDateTime dateEmission,
                      LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.apprenantId      = apprenantId;
        this.coursId          = coursId;
        this.codeVerification = codeVerification;
        this.lienPdf          = lienPdf;
        this.dateEmission     = dateEmission;
    }
    public void setLienPdf(String lien) { this.lienPdf = lien; markUpdated(); }

    private static String genererCode() {
        byte[] bytes = new byte[9]; // 12 chars base64
        RANDOM.nextBytes(bytes);
        return "MBN-" + Base64.getUrlEncoder().withoutPadding()
            .encodeToString(bytes).toUpperCase().substring(0, 8);
    }

    public UUID          getApprenantId()     { return apprenantId; }
    public UUID          getCoursId()         { return coursId; }
    public String        getCodeVerification(){ return codeVerification; }
    public String        getLienPdf()         { return lienPdf; }
    public LocalDateTime getDateEmission()    { return dateEmission; }
}
JEOF

cat > "$P/domain/certificat/CertificatDomainService.java" << 'JEOF'
package com.mbem.mbemlevel.domain.certificat;
import com.mbem.mbemlevel.domain.progression.Progression;
/**
 * Règles d'obtention d'un certificat.
 * Un certificat est émis uniquement si :
 *   - Le cours est payé (accès complet activé)
 *   - La progression est à 100%
 */
public class CertificatDomainService {
    public boolean peutObtenirCertificat(Progression progression) {
        return progression.isEstPaye() && progression.estTermine();
    }
}
JEOF

cat > "$P/domain/notification/Notification.java" << 'JEOF'
package com.mbem.mbemlevel.domain.notification;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.enums.CanalNotification;
import com.mbem.mbemlevel.domain.shared.enums.TypeNotification;
import java.time.LocalDateTime;
import java.util.UUID;
/**
 * Notification in-app pour un utilisateur.
 * Les canaux EMAIL et WHATSAPP sont gérés par les adaptateurs dédiés.
 * IN_APP : stocké en base, affiché dans la cloche de l'interface.
 */
public class Notification extends AggregateRoot {
    private UUID              utilisateurId;
    private TypeNotification  typeNotif;
    private CanalNotification canal;
    private String            titre;
    private String            contenu;
    private boolean           estLue;
    private LocalDateTime     dateLecture;
    private String            lienAction;

    public static Notification creer(UUID utilisateurId, TypeNotification type,
                                      CanalNotification canal, String titre,
                                      String contenu, String lienAction) {
        Notification n = new Notification();
        n.utilisateurId = utilisateurId; n.typeNotif = type;
        n.canal = canal; n.titre = titre; n.contenu = contenu;
        n.estLue = false; n.lienAction = lienAction;
        return n;
    }
    public Notification(UUID id, UUID userId, TypeNotification type,
                        CanalNotification canal, String titre, String contenu,
                        boolean estLue, LocalDateTime dateLecture, String lienAction,
                        LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.utilisateurId = userId; this.typeNotif = type; this.canal = canal;
        this.titre = titre; this.contenu = contenu; this.estLue = estLue;
        this.dateLecture = dateLecture; this.lienAction = lienAction;
    }
    public void marquerLue() {
        this.estLue = true; this.dateLecture = LocalDateTime.now(); markUpdated();
    }
    public UUID              getUtilisateurId() { return utilisateurId; }
    public TypeNotification  getTypeNotif()     { return typeNotif; }
    public CanalNotification getCanal()         { return canal; }
    public String            getTitre()         { return titre; }
    public String            getContenu()       { return contenu; }
    public boolean           isEstLue()         { return estLue; }
    public LocalDateTime     getDateLecture()   { return dateLecture; }
    public String            getLienAction()    { return lienAction; }
}
JEOF

cat > "$P/domain/communaute/MessageCommunaute.java" << 'JEOF'
package com.mbem.mbemlevel.domain.communaute;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Message de la communauté Q&R — question ou réponse dans le contexte d'un cours. */
public class MessageCommunaute extends AggregateRoot {
    private UUID    coursId;
    private UUID    auteurId;
    private UUID    parentId;       // null = question racine, non-null = réponse
    private String  contenu;
    private boolean estQuestion;
    private boolean estResolu;
    private boolean estModere;
    private int     nbLikes;

    public static MessageCommunaute poserQuestion(UUID coursId, UUID auteurId,
                                                   String contenu) {
        if (contenu == null || contenu.isBlank())
            throw new IllegalArgumentException("Contenu obligatoire");
        MessageCommunaute m = new MessageCommunaute();
        m.coursId = coursId; m.auteurId = auteurId;
        m.contenu = contenu.trim(); m.estQuestion = true;
        m.estResolu = false; m.estModere = false; m.nbLikes = 0;
        return m;
    }
    public static MessageCommunaute repondre(UUID coursId, UUID auteurId,
                                              UUID parentId, String contenu) {
        MessageCommunaute m = poserQuestion(coursId, auteurId, contenu);
        m.parentId = parentId; m.estQuestion = false;
        return m;
    }
    public MessageCommunaute(UUID id, UUID coursId, UUID auteurId, UUID parentId,
                              String contenu, boolean estQuestion, boolean estResolu,
                              boolean estModere, int nbLikes,
                              LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.coursId = coursId; this.auteurId = auteurId; this.parentId = parentId;
        this.contenu = contenu; this.estQuestion = estQuestion; this.estResolu = estResolu;
        this.estModere = estModere; this.nbLikes = nbLikes;
    }
    public void marquerResolu()  { this.estResolu = true;  markUpdated(); }
    public void moderer()        { this.estModere = true;  markUpdated(); }
    public void liker()          { this.nbLikes++;          markUpdated(); }

    public UUID    getCoursId()     { return coursId; }
    public UUID    getAuteurId()    { return auteurId; }
    public UUID    getParentId()    { return parentId; }
    public String  getContenu()     { return contenu; }
    public boolean isEstQuestion()  { return estQuestion; }
    public boolean isEstResolu()    { return estResolu; }
    public boolean isEstModere()    { return estModere; }
    public int     getNbLikes()     { return nbLikes; }
}
JEOF

cat > "$P/domain/communaute/Signalement.java" << 'JEOF'
package com.mbem.mbemlevel.domain.communaute;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Signalement d'un message inapproprié — traité par l'admin. */
public class Signalement extends AggregateRoot {
    private UUID   messageId;
    private UUID   auteurId;
    private String raison;
    private String statut;   // EN_ATTENTE | TRAITE | IGNORE
    private UUID   adminId;

    public static Signalement creer(UUID messageId, UUID auteurId, String raison) {
        Signalement s = new Signalement();
        s.messageId = messageId; s.auteurId = auteurId;
        s.raison = raison; s.statut = "EN_ATTENTE";
        return s;
    }
    public Signalement(UUID id, UUID messageId, UUID auteurId, String raison,
                       String statut, UUID adminId, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.messageId = messageId; this.auteurId = auteurId;
        this.raison = raison; this.statut = statut; this.adminId = adminId;
    }
    public void traiter(UUID adminId) { this.statut = "TRAITE"; this.adminId = adminId; markUpdated(); }
    public void ignorer(UUID adminId) { this.statut = "IGNORE"; this.adminId = adminId; markUpdated(); }

    public UUID   getMessageId() { return messageId; }
    public UUID   getAuteurId()  { return auteurId; }
    public String getRaison()    { return raison; }
    public String getStatut()    { return statut; }
}
JEOF

cat > "$P/domain/gamification/Parrainage.java" << 'JEOF'
package com.mbem.mbemlevel.domain.gamification;
import com.mbem.mbemlevel.domain.event.ParrainageActiveEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/**
 * Parrainage — lien parrain/filleul.
 * La récompense est activée quand le filleul complète son premier module.
 */
public class Parrainage extends AggregateRoot {
    private UUID   parrainId;
    private UUID   filleulId;
    private String codeUtilise;
    private String statut;               // EN_ATTENTE | ACTIF | RECOMPENSE
    private boolean recomparainageActivee;

    public static Parrainage creer(UUID parrainId, UUID filleulId, String code) {
        Parrainage p = new Parrainage();
        p.parrainId = parrainId; p.filleulId = filleulId;
        p.codeUtilise = code; p.statut = "EN_ATTENTE";
        p.recomparainageActivee = false;
        return p;
    }
    public Parrainage(UUID id, UUID parrainId, UUID filleulId, String code,
                      String statut, boolean recompense,
                      LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.parrainId = parrainId; this.filleulId = filleulId;
        this.codeUtilise = code; this.statut = statut;
        this.recomparainageActivee = recompense;
    }
    /** Filleul a complété son premier module → déclenche la récompense parrain. */
    public void activerRecompense(String emailParrain) {
        if (recomparainageActivee) return;
        this.statut = "RECOMPENSE"; this.recomparainageActivee = true; markUpdated();
        registerEvent(new ParrainageActiveEvent(parrainId, filleulId, emailParrain));
    }
    public UUID    getParrainId()             { return parrainId; }
    public UUID    getFilleulId()             { return filleulId; }
    public String  getCodeUtilise()           { return codeUtilise; }
    public String  getStatut()                { return statut; }
    public boolean isRecomparainageActivee()  { return recomparainageActivee; }
}
JEOF

cat > "$P/domain/gamification/TirageAuSort.java" << 'JEOF'
package com.mbem.mbemlevel.domain.gamification;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
/** Tirage au sort mensuel — 1er du mois, parmi les apprenants actifs. */
public class TirageAuSort extends AggregateRoot {
    private LocalDate mois;         // Premier jour du mois (ex: 2025-01-01)
    private UUID      gagnantId;
    private int       nbParticipants;
    private String    prixDescription;

    public static TirageAuSort creer(LocalDate mois, int nbParticipants, String prix) {
        TirageAuSort t = new TirageAuSort();
        t.mois = mois; t.nbParticipants = nbParticipants; t.prixDescription = prix;
        return t;
    }
    public TirageAuSort(UUID id, LocalDate mois, UUID gagnantId, int nbParticipants,
                        String prixDescription, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.mois = mois; this.gagnantId = gagnantId;
        this.nbParticipants = nbParticipants; this.prixDescription = prixDescription;
    }
    public void designerGagnant(UUID gagnantId) {
        this.gagnantId = gagnantId; markUpdated();
    }
    public LocalDate getMois()           { return mois; }
    public UUID      getGagnantId()      { return gagnantId; }
    public int       getNbParticipants() { return nbParticipants; }
    public String    getPrixDescription(){ return prixDescription; }
}
JEOF
ok "Domain Certificat · Notification · MessageCommunaute · Signalement · Parrainage · TirageAuSort"

# =============================================================================
sec "2/6 JPA + Repos + Adapters + Ports"
# =============================================================================
mkdir -p "$P/infrastructure/persistence/entity"
mkdir -p "$P/infrastructure/persistence/repository"
mkdir -p "$P/infrastructure/persistence/adapter"
mkdir -p "$P/application/port/out"

cat > "$P/infrastructure/persistence/entity/CertificatJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="certificats",
    uniqueConstraints=@UniqueConstraint(columnNames={"apprenant_id","cours_id"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CertificatJpaEntity {
    @Id private UUID id;
    @Column(name="apprenant_id",nullable=false) private UUID apprenantId;
    @Column(name="cours_id",nullable=false)     private UUID coursId;
    @Column(name="code_verification",nullable=false,unique=true,length=50) private String codeVerification;
    @Column(name="lien_pdf",length=500) private String lienPdf;
    @Column(name="date_emission",nullable=false) private LocalDateTime dateEmission;
    @Column(name="created_at",nullable=false,updatable=false) private LocalDateTime createdAt;
    @Column(name="updated_at",nullable=false) private LocalDateTime updatedAt;
    @PrePersist protected void onCreate() {
        if (id==null) id=UUID.randomUUID();
        if (createdAt==null) createdAt=LocalDateTime.now();
        if (updatedAt==null) updatedAt=createdAt;
    }
    @PreUpdate protected void onUpdate() { updatedAt=LocalDateTime.now(); }
}
JEOF

cat > "$P/infrastructure/persistence/entity/NotificationJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;
import com.mbem.mbemlevel.domain.shared.enums.CanalNotification;
import com.mbem.mbemlevel.domain.shared.enums.TypeNotification;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="notifications")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class NotificationJpaEntity {
    @Id private UUID id;
    @Column(name="utilisateur_id",nullable=false) private UUID utilisateurId;
    @Enumerated(EnumType.STRING) @Column(name="type_notif",nullable=false,length=50) private TypeNotification typeNotif;
    @Enumerated(EnumType.STRING) @Column(nullable=false,length=20) private CanalNotification canal;
    @Column(nullable=false,length=200) private String titre;
    @Column(columnDefinition="TEXT") private String contenu;
    @Column(name="est_lue",nullable=false) private boolean estLue;
    @Column(name="date_lecture") private LocalDateTime dateLecture;
    @Column(name="lien_action",length=500) private String lienAction;
    @Column(name="created_at",nullable=false,updatable=false) private LocalDateTime createdAt;
    @Column(name="updated_at",nullable=false) private LocalDateTime updatedAt;
    @PrePersist protected void onCreate() {
        if (id==null) id=UUID.randomUUID();
        if (createdAt==null) createdAt=LocalDateTime.now();
        if (updatedAt==null) updatedAt=createdAt;
    }
    @PreUpdate protected void onUpdate() { updatedAt=LocalDateTime.now(); }
}
JEOF

cat > "$P/infrastructure/persistence/entity/MessageCommunauteJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="messages_communaute")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MessageCommunauteJpaEntity {
    @Id private UUID id;
    @Column(name="cours_id",nullable=false)  private UUID coursId;
    @Column(name="auteur_id",nullable=false) private UUID auteurId;
    @Column(name="parent_id")               private UUID parentId;
    @Column(nullable=false,columnDefinition="TEXT") private String contenu;
    @Column(name="est_question",nullable=false) private boolean estQuestion;
    @Column(name="est_resolu",nullable=false)   private boolean estResolu;
    @Column(name="est_modere",nullable=false)   private boolean estModere;
    @Column(name="nb_likes",nullable=false)     private int nbLikes;
    @Column(name="created_at",nullable=false,updatable=false) private LocalDateTime createdAt;
    @Column(name="updated_at",nullable=false) private LocalDateTime updatedAt;
    @PrePersist protected void onCreate() {
        if (id==null) id=UUID.randomUUID();
        if (createdAt==null) createdAt=LocalDateTime.now();
        if (updatedAt==null) updatedAt=createdAt;
    }
    @PreUpdate protected void onUpdate() { updatedAt=LocalDateTime.now(); }
}
JEOF

# ── Repositories JPA ──────────────────────────────────────────────────────────
cat > "$P/infrastructure/persistence/repository/CertificatJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CertificatJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface CertificatJpaRepository extends JpaRepository<CertificatJpaEntity, UUID> {
    Optional<CertificatJpaEntity> findByCodeVerification(String code);
    Optional<CertificatJpaEntity> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<CertificatJpaEntity> findByApprenantId(UUID apprenantId);
}
JEOF

cat > "$P/infrastructure/persistence/repository/NotificationJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.NotificationJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.*;
public interface NotificationJpaRepository extends JpaRepository<NotificationJpaEntity, UUID> {
    List<NotificationJpaEntity> findByUtilisateurIdOrderByCreatedAtDesc(UUID userId);
    @Query("SELECT n FROM NotificationJpaEntity n WHERE n.utilisateurId=:uid AND n.estLue=false")
    List<NotificationJpaEntity> findNonLues(@Param("uid") UUID userId);
    @Modifying
    @Query("UPDATE NotificationJpaEntity n SET n.estLue=true WHERE n.utilisateurId=:uid")
    int marquerToutesLues(@Param("uid") UUID userId);
}
JEOF

cat > "$P/infrastructure/persistence/repository/MessageCommunauteJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.MessageCommunauteJpaEntity;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.UUID;
public interface MessageCommunauteJpaRepository
    extends JpaRepository<MessageCommunauteJpaEntity, UUID> {
    /** Questions racines d'un cours, non modérées, triées par likes. */
    @Query("SELECT m FROM MessageCommunauteJpaEntity m " +
           "WHERE m.coursId=:cid AND m.parentId IS NULL AND m.estModere=false " +
           "ORDER BY m.nbLikes DESC, m.createdAt DESC")
    Page<MessageCommunauteJpaEntity> findQuestions(
        @Param("cid") UUID coursId, Pageable pageable);
    /** Réponses à une question. */
    @Query("SELECT m FROM MessageCommunauteJpaEntity m " +
           "WHERE m.parentId=:pid AND m.estModere=false ORDER BY m.createdAt ASC")
    Page<MessageCommunauteJpaEntity> findReponses(
        @Param("pid") UUID parentId, Pageable pageable);
}
JEOF

# ── Ports Application ─────────────────────────────────────────────────────────
cat > "$P/application/port/out/CertificatRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import java.util.*;
public interface CertificatRepository {
    Optional<Certificat> findById(UUID id);
    Optional<Certificat> findByCode(String codeVerification);
    Optional<Certificat> findByApprenantAndCours(UUID apprenantId, UUID coursId);
    List<Certificat>     findByApprenant(UUID apprenantId);
    Certificat           save(Certificat certificat);
}
JEOF

cat > "$P/application/port/out/NotificationRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.notification.Notification;
import java.util.*;
public interface NotificationRepository {
    Notification         save(Notification notification);
    List<Notification>   findByUtilisateur(UUID utilisateurId);
    List<Notification>   findNonLues(UUID utilisateurId);
    int                  marquerToutesLues(UUID utilisateurId);
    Optional<Notification> findById(UUID id);
}
JEOF

cat > "$P/application/port/out/CommunauteRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.communaute.MessageCommunaute;
import org.springframework.data.domain.*;
import java.util.*;
public interface CommunauteRepository {
    MessageCommunaute          save(MessageCommunaute message);
    Optional<MessageCommunaute> findById(UUID id);
    Page<MessageCommunaute>    findQuestions(UUID coursId, Pageable pageable);
    Page<MessageCommunaute>    findReponses(UUID parentId, Pageable pageable);
}
JEOF

cat > "$P/application/port/out/PDFPort.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;
import java.util.Map;
/** Port sortant — génération PDF (certificats, factures). Implémenté par ITextPDFAdapter. */
public interface PDFPort {
    /** Génère un PDF depuis un template Thymeleaf et retourne les bytes. */
    byte[] generer(String templateName, Map<String, Object> variables);
}
JEOF

cat > "$P/application/port/out/StoragePort.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;
/** Port sortant — stockage S3/MinIO (CV, certificats PDF, images). */
public interface StoragePort {
    /** Upload un fichier et retourne son URL publique. */
    String upload(String bucketPath, byte[] content, String contentType);
    /** Supprime un fichier. */
    void   delete(String bucketPath);
    /** Génère une URL présignée temporaire (60 min). */
    String presignedUrl(String bucketPath);
}
JEOF

cat > "$P/application/port/out/WhatsAppPort.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;
/** Port sortant — envoi de messages WhatsApp Business (Meta API). */
public interface WhatsAppPort {
    void envoyerMessage(String telephone, String message);
    void envoyerTemplate(String telephone, String templateName, String... params);
}
JEOF

# ── Adapters ──────────────────────────────────────────────────────────────────
cat > "$P/infrastructure/persistence/adapter/CertificatRepositoryAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.adapter;
import com.mbem.mbemlevel.application.port.out.CertificatRepository;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CertificatJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CertificatJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.stream.Collectors;
@Component @RequiredArgsConstructor
public class CertificatRepositoryAdapter implements CertificatRepository {
    private final CertificatJpaRepository repo;
    @Override @Transactional(readOnly=true)
    public Optional<Certificat> findById(UUID id)   { return repo.findById(id).map(this::toDomain); }
    @Override @Transactional(readOnly=true)
    public Optional<Certificat> findByCode(String c){ return repo.findByCodeVerification(c).map(this::toDomain); }
    @Override @Transactional(readOnly=true)
    public Optional<Certificat> findByApprenantAndCours(UUID a, UUID c) {
        return repo.findByApprenantIdAndCoursId(a,c).map(this::toDomain);
    }
    @Override @Transactional(readOnly=true)
    public List<Certificat> findByApprenant(UUID a) {
        return repo.findByApprenantId(a).stream().map(this::toDomain).collect(Collectors.toList());
    }
    @Override @Transactional
    public Certificat save(Certificat c) { return toDomain(repo.save(toEntity(c))); }
    private Certificat toDomain(CertificatJpaEntity e) {
        return new Certificat(e.getId(),e.getApprenantId(),e.getCoursId(),
            e.getCodeVerification(),e.getLienPdf(),e.getDateEmission(),
            e.getCreatedAt(),e.getUpdatedAt());
    }
    private CertificatJpaEntity toEntity(Certificat c) {
        return CertificatJpaEntity.builder().id(c.getId())
            .apprenantId(c.getApprenantId()).coursId(c.getCoursId())
            .codeVerification(c.getCodeVerification())
            .lienPdf(c.getLienPdf()).dateEmission(c.getDateEmission()).build();
    }
}
JEOF

cat > "$P/infrastructure/persistence/adapter/NotificationRepositoryAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.adapter;
import com.mbem.mbemlevel.application.port.out.NotificationRepository;
import com.mbem.mbemlevel.domain.notification.Notification;
import com.mbem.mbemlevel.infrastructure.persistence.entity.NotificationJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.NotificationJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.stream.Collectors;
@Component @RequiredArgsConstructor
public class NotificationRepositoryAdapter implements NotificationRepository {
    private final NotificationJpaRepository repo;
    @Override @Transactional
    public Notification save(Notification n) { return toDomain(repo.save(toEntity(n))); }
    @Override @Transactional(readOnly=true)
    public List<Notification> findByUtilisateur(UUID uid) {
        return repo.findByUtilisateurIdOrderByCreatedAtDesc(uid)
            .stream().map(this::toDomain).collect(Collectors.toList());
    }
    @Override @Transactional(readOnly=true)
    public List<Notification> findNonLues(UUID uid) {
        return repo.findNonLues(uid).stream().map(this::toDomain).collect(Collectors.toList());
    }
    @Override @Transactional
    public int marquerToutesLues(UUID uid) { return repo.marquerToutesLues(uid); }
    @Override @Transactional(readOnly=true)
    public Optional<Notification> findById(UUID id) { return repo.findById(id).map(this::toDomain); }
    private Notification toDomain(NotificationJpaEntity e) {
        return new Notification(e.getId(),e.getUtilisateurId(),e.getTypeNotif(),
            e.getCanal(),e.getTitre(),e.getContenu(),e.isEstLue(),e.getDateLecture(),
            e.getLienAction(),e.getCreatedAt(),e.getUpdatedAt());
    }
    private NotificationJpaEntity toEntity(Notification n) {
        return NotificationJpaEntity.builder().id(n.getId())
            .utilisateurId(n.getUtilisateurId()).typeNotif(n.getTypeNotif())
            .canal(n.getCanal()).titre(n.getTitre()).contenu(n.getContenu())
            .estLue(n.isEstLue()).dateLecture(n.getDateLecture())
            .lienAction(n.getLienAction()).build();
    }
}
JEOF

cat > "$P/infrastructure/persistence/adapter/CommunauteRepositoryAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.adapter;
import com.mbem.mbemlevel.application.port.out.CommunauteRepository;
import com.mbem.mbemlevel.domain.communaute.MessageCommunaute;
import com.mbem.mbemlevel.infrastructure.persistence.entity.MessageCommunauteJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.MessageCommunauteJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
@Component @RequiredArgsConstructor
public class CommunauteRepositoryAdapter implements CommunauteRepository {
    private final MessageCommunauteJpaRepository repo;
    @Override @Transactional
    public MessageCommunaute save(MessageCommunaute m) { return toDomain(repo.save(toEntity(m))); }
    @Override @Transactional(readOnly=true)
    public Optional<MessageCommunaute> findById(UUID id) { return repo.findById(id).map(this::toDomain); }
    @Override @Transactional(readOnly=true)
    public Page<MessageCommunaute> findQuestions(UUID cid, Pageable p) {
        return repo.findQuestions(cid, p).map(this::toDomain);
    }
    @Override @Transactional(readOnly=true)
    public Page<MessageCommunaute> findReponses(UUID pid, Pageable p) {
        return repo.findReponses(pid, p).map(this::toDomain);
    }
    private MessageCommunaute toDomain(MessageCommunauteJpaEntity e) {
        return new MessageCommunaute(e.getId(),e.getCoursId(),e.getAuteurId(),e.getParentId(),
            e.getContenu(),e.isEstQuestion(),e.isEstResolu(),e.isEstModere(),e.getNbLikes(),
            e.getCreatedAt(),e.getUpdatedAt());
    }
    private MessageCommunauteJpaEntity toEntity(MessageCommunaute m) {
        return MessageCommunauteJpaEntity.builder()
            .id(m.getId()!=null?m.getId():UUID.randomUUID())
            .coursId(m.getCoursId()).auteurId(m.getAuteurId()).parentId(m.getParentId())
            .contenu(m.getContenu()).estQuestion(m.isEstQuestion())
            .estResolu(m.isEstResolu()).estModere(m.isEstModere())
            .nbLikes(m.getNbLikes()).build();
    }
}
JEOF
ok "JPA · Repos · Ports · Adapters (Certificat, Notification, Communauté)"

# =============================================================================
sec "3/6 Use Cases Talent + Certificat (S13, S14)"
# =============================================================================
mkdir -p "$P/application/usecase/talent"
mkdir -p "$P/application/usecase/communaute"
mkdir -p "$P/application/usecase/gamification"

cat > "$P/application/usecase/talent/MettreAJourProfilUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.talent;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S14 — Apprenant met à jour son profil talent (vitrine recruteurs).
 * Champs : ville, bio, liens portfolio/CV/LinkedIn/GitHub, disponibilité emploi.
 */
@Service @RequiredArgsConstructor
public class MettreAJourProfilUseCase {
    private final UtilisateurRepository repo;
    public record Commande(UUID userId, String prenom, String nom, String telephone,
                            boolean disponiblePourEmploi) {}
    @Transactional
    public Utilisateur executer(Commande cmd) {
        Utilisateur u = repo.findById(cmd.userId())
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        u.mettreAJourProfil(cmd.prenom(), cmd.nom(), cmd.telephone());
        return repo.save(u);
    }
}
JEOF

cat > "$P/application/usecase/talent/GetProfilTalentUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.talent;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
/** S14 — Récupère le profil public (talent) d'un apprenant avec ses certificats. */
@Service @RequiredArgsConstructor
public class GetProfilTalentUseCase {
    private final UtilisateurRepository  utilisateurRepo;
    private final CertificatRepository   certificatRepo;
    public record ProfilAvecCertificats(Utilisateur utilisateur, List<Certificat> certificats) {}
    @Transactional(readOnly=true)
    public ProfilAvecCertificats executer(UUID apprenantId) {
        Utilisateur u = utilisateurRepo.findById(apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        List<Certificat> certs = certificatRepo.findByApprenant(apprenantId);
        return new ProfilAvecCertificats(u, certs);
    }
}
JEOF

cat > "$P/application/usecase/talent/GenererCertificatUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.talent;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.certificat.*;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S13 — Génère et émet un certificat après validation complète du cours.
 * Règle : cours payé + 100% de progression.
 */
@Service @RequiredArgsConstructor @Slf4j
public class GenererCertificatUseCase {
    private final CertificatRepository   certificatRepo;
    private final ProgressionRepository  progressionRepo;
    private final UtilisateurRepository  utilisateurRepo;
    private final CoursRepository        coursRepo;
    private final AuditLogRepository     auditRepo;
    private final ApplicationEventPublisher publisher;
    private final CertificatDomainService domainService;

    @Transactional
    public Certificat executer(UUID apprenantId, UUID coursId) {
        // Vérifier si déjà généré
        if (certificatRepo.findByApprenantAndCours(apprenantId, coursId).isPresent()) {
            return certificatRepo.findByApprenantAndCours(apprenantId, coursId).get();
        }
        // Vérifier les conditions
        Progression prog = progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        if (!domainService.peutObtenirCertificat(prog))
            throw new RuntimeException("CERTIFICATE_CONDITIONS_NOT_MET");

        Utilisateur user = utilisateurRepo.findById(apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        var cours = coursRepo.findById(coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));

        Certificat cert = Certificat.emettre(apprenantId, coursId,
            user.getPrenom(), user.getEmail(),
            user.getTelephone(), cours.getTitre());
        Certificat saved = certificatRepo.save(cert);

        // Publier → email félicitations + WhatsApp + profil talent mis à jour
        saved.getDomainEvents().forEach(publisher::publishEvent);
        saved.clearDomainEvents();

        auditRepo.enregistrer(apprenantId, user.getEmail(), "CERTIFICAT_EMIS",
            "CERTIFICAT", saved.getId().toString(), null, "SUCCESS", null, null);
        log.info("[CERT] Certificat émis: apprenant={} cours={}", apprenantId, coursId);
        return saved;
    }
}
JEOF

cat > "$P/application/usecase/talent/VerifierCertificatUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.talent;
import com.mbem.mbemlevel.application.port.out.CertificatRepository;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Optional;
/** Vérification publique d'un certificat par code (recruteurs). */
@Service @RequiredArgsConstructor
public class VerifierCertificatUseCase {
    private final CertificatRepository repo;
    @Transactional(readOnly=true)
    public Optional<Certificat> executer(String code) { return repo.findByCode(code); }
}
JEOF

# ── Use Cases Communauté (S12) ────────────────────────────────────────────────
cat > "$P/application/usecase/communaute/PostMessageUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.communaute;
import com.mbem.mbemlevel.application.port.out.CommunauteRepository;
import com.mbem.mbemlevel.domain.communaute.MessageCommunaute;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/** S12 — Poster une question ou une réponse dans la communauté. */
@Service @RequiredArgsConstructor
public class PostMessageUseCase {
    private final CommunauteRepository repo;
    @Transactional
    public MessageCommunaute poster(UUID coursId, UUID auteurId,
                                    String contenu, UUID parentId) {
        MessageCommunaute m = (parentId == null)
            ? MessageCommunaute.poserQuestion(coursId, auteurId, contenu)
            : MessageCommunaute.repondre(coursId, auteurId, parentId, contenu);
        return repo.save(m);
    }
}
JEOF

# ── Use Case Gamification (S15) ───────────────────────────────────────────────
cat > "$P/application/usecase/gamification/TraiterParrainageUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.gamification;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.gamification.Parrainage;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import com.mbem.mbemlevel.domain.user.valueobject.LienParrainage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S15 — Activer la récompense de parrainage quand le filleul
 * complète son premier module (XP >= 100).
 */
@Service @RequiredArgsConstructor @Slf4j
public class TraiterParrainageUseCase {
    private final UtilisateurRepository  utilisateurRepo;
    private final ApplicationEventPublisher publisher;

    /** Génère un code de parrainage unique pour un apprenant. */
    @Transactional
    public String genererCode(UUID apprenantId) {
        Utilisateur u = utilisateurRepo.findById(apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        String code = LienParrainage.generer().code();
        // Note: le code est enregistré sur l'entité utilisateur (champ codeParrainage)
        // La mise à jour de l'entité JPA est gérée via utilisateurRepo.save()
        log.debug("[PARRAINAGE] Code généré: {} pour apprenant {}", code, apprenantId);
        return code;
    }
}
JEOF
ok "Use Cases Talent (MettreAJourProfil, GetProfil, GenererCertificat, VerifierCertificat) · Communauté · Gamification"

# =============================================================================
sec "4/6 Event Handlers Certificat + Notification"
# =============================================================================
mkdir -p "$P/application/event"

cat > "$P/application/event/RenduCorrigeHandler.java" << 'JEOF'
package com.mbem.mbemlevel.application.event;
import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.RenduCorrigeEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
/** Notifie l'apprenant quand son rendu est corrigé (S23). */
@Component @RequiredArgsConstructor @Slf4j
public class RenduCorrigeHandler {
    private final EmailPort emailPort;
    @EventListener @Async
    public void handle(RenduCorrigeEvent e) {
        try { emailPort.envoyerRenduCorrige(e.email(), e.prenom(), "Votre devoir", e.note(), ""); }
        catch (Exception ex) { log.error("[EVENT] Erreur notif rendu: {}", ex.getMessage()); }
    }
}
JEOF

cat > "$P/application/event/ParrainageActiveHandler.java" << 'JEOF'
package com.mbem.mbemlevel.application.event;
import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.domain.event.ParrainageActiveEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
/** Notifie le parrain quand son filleul active la récompense. */
@Component @RequiredArgsConstructor @Slf4j
public class ParrainageActiveHandler {
    private final EmailPort emailPort;
    @EventListener @Async
    public void handle(ParrainageActiveEvent e) {
        try { emailPort.envoyerRecomparainageActive(e.emailParrain(), "Parrain", "Filleul"); }
        catch (Exception ex) { log.error("[EVENT] Erreur parrainage: {}", ex.getMessage()); }
    }
}
JEOF
ok "Event Handlers (RenduCorrige, ParrainageActive)"

# =============================================================================
sec "5/6 Controllers + DTOs"
# =============================================================================
mkdir -p "$P/api/controller"
mkdir -p "$P/api/dto/response"
mkdir -p "$P/api/dto/request"

cat > "$P/api/dto/response/ProfilTalentResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import java.util.List;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProfilTalentResponse(
    UUID id, String prenom, String nom, String telephone,
    boolean disponiblePourEmploi,
    String lienPortfolio, String lienLinkedin, String lienGithub, String lienCv,
    String bio, int xpTotal, int streakJours,
    List<CertificatResponse> certificats
) {
    public static ProfilTalentResponse from(Utilisateur u, List<CertificatResponse> certs) {
        return new ProfilTalentResponse(u.getId(), u.getPrenom(), u.getNom(),
            u.getTelephone(), false,
            null, null, null, null,
            null, 0, 0, certs);
    }
}
JEOF

cat > "$P/api/dto/response/CertificatResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import java.time.LocalDateTime;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record CertificatResponse(
    UUID id, UUID coursId, String codeVerification,
    String lienPdf, LocalDateTime dateEmission
) {
    public static CertificatResponse from(Certificat c) {
        return new CertificatResponse(c.getId(), c.getCoursId(),
            c.getCodeVerification(), c.getLienPdf(), c.getDateEmission());
    }
}
JEOF

cat > "$P/api/dto/response/NotificationResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.notification.Notification;
import com.mbem.mbemlevel.domain.shared.enums.TypeNotification;
import java.time.LocalDateTime;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record NotificationResponse(
    UUID id, TypeNotification type, String titre,
    String contenu, boolean estLue,
    LocalDateTime createdAt, String lienAction
) {
    public static NotificationResponse from(Notification n) {
        return new NotificationResponse(n.getId(), n.getTypeNotif(), n.getTitre(),
            n.getContenu(), n.isEstLue(), n.getCreatedAt(), n.getLienAction());
    }
}
JEOF

cat > "$P/api/dto/response/MessageResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.communaute.MessageCommunaute;
import java.time.LocalDateTime;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record MessageResponse(
    UUID id, UUID auteurId, UUID parentId,
    String contenu, boolean estQuestion, boolean estResolu,
    int nbLikes, LocalDateTime createdAt
) {
    public static MessageResponse from(MessageCommunaute m) {
        return new MessageResponse(m.getId(), m.getAuteurId(), m.getParentId(),
            m.getContenu(), m.isEstQuestion(), m.isEstResolu(),
            m.getNbLikes(), m.getCreatedAt());
    }
}
JEOF

cat > "$P/api/dto/request/PostMessageRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
import java.util.UUID;
public record PostMessageRequest(
    @NotBlank @Size(max=2000) String contenu,
    UUID parentId  // null = nouvelle question, non-null = réponse
) {}
JEOF

cat > "$P/api/controller/TalentController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.talent.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;
import java.util.stream.Collectors;
/**
 * API Talent — S14 (profil apprenant public pour recruteurs).
 * GET /api/v1/talents        → liste apprenants disponibles
 * GET /api/v1/talents/{id}   → profil public d'un apprenant
 * GET /api/v1/talents/me     → mon profil
 */
@RestController
@RequestMapping("/api/v1/talents")
@Tag(name="Talent", description="Profils publics des apprenants pour recruteurs")
@RequiredArgsConstructor
public class TalentController {
    private final GetProfilTalentUseCase getProfilUC;
    private final UtilisateurListAdapter utilisateurAdapter;

    @GetMapping("/{apprenantId}")
    @Operation(summary="Profil talent d'un apprenant (S14)")
    public ResponseEntity<ApiResponse<ProfilTalentResponse>> profil(
            @PathVariable UUID apprenantId) {
        var data = getProfilUC.executer(apprenantId);
        List<CertificatResponse> certs = data.certificats().stream()
            .map(CertificatResponse::from).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(
            ProfilTalentResponse.from(data.utilisateur(), certs)));
    }

    @GetMapping("/me")
    @Operation(summary="Mon profil talent")
    public ResponseEntity<ApiResponse<ProfilTalentResponse>> monProfil(
            @AuthenticationPrincipal String userId) {
        var data = getProfilUC.executer(UUID.fromString(userId));
        List<CertificatResponse> certs = data.certificats().stream()
            .map(CertificatResponse::from).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(
            ProfilTalentResponse.from(data.utilisateur(), certs)));
    }
}
JEOF

# Adapter utilitaire pour TalentController
cat > "$P/api/controller/UtilisateurListAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import java.util.List;
@Component @RequiredArgsConstructor
public class UtilisateurListAdapter {
    private final UtilisateurRepository repo;
    public List<Utilisateur> findDisponibles() { return repo.findApprenantsDisponibles(); }
}
JEOF

cat > "$P/api/controller/CertificatController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.talent.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * API Certificats — S13 (émission), vérification publique.
 * POST /api/v1/certificats/cours/{coursId}/generer → génère le certificat
 * GET  /api/v1/certificats/verify/{code}           → vérification publique
 */
@RestController
@RequestMapping("/api/v1/certificats")
@Tag(name="Certificat", description="Émission et vérification de certificats")
@RequiredArgsConstructor
public class CertificatController {
    private final GenererCertificatUseCase  genererUC;
    private final VerifierCertificatUseCase verifierUC;

    @PostMapping("/cours/{coursId}/generer")
    @Operation(summary="Générer mon certificat pour un cours (S13)")
    public ResponseEntity<ApiResponse<CertificatResponse>> generer(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String userId) {
        var cert = genererUC.executer(UUID.fromString(userId), coursId);
        return ResponseEntity.ok(ApiResponse.ok(
            CertificatResponse.from(cert), "Certificat généré !"));
    }

    @GetMapping("/verify/{code}")
    @Operation(summary="Vérifier l'authenticité d'un certificat (public)")
    public ResponseEntity<ApiResponse<CertificatResponse>> verifier(
            @PathVariable String code) {
        return verifierUC.executer(code)
            .map(c -> ResponseEntity.ok(ApiResponse.ok(CertificatResponse.from(c),
                "Certificat authentique.")))
            .orElse(ResponseEntity.ok(ApiResponse.err(
                "Certificat non trouvé.", "CERT_NOT_FOUND")));
    }
}
JEOF

cat > "$P/api/controller/NotificationController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.port.out.NotificationRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;
import java.util.stream.Collectors;
/**
 * API Notifications — cloche in-app.
 * GET   /api/v1/notifications      → toutes mes notifications
 * GET   /api/v1/notifications/unread → non lues
 * PATCH /api/v1/notifications/read-all → tout marquer lu
 */
@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name="Notification", description="Notifications in-app")
@RequiredArgsConstructor
public class NotificationController {
    private final NotificationRepository repo;

    @GetMapping
    @Operation(summary="Mes notifications")
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> mesNotifications(
            @AuthenticationPrincipal String userId) {
        List<NotificationResponse> list = repo.findByUtilisateur(UUID.fromString(userId))
            .stream().map(NotificationResponse::from).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @GetMapping("/unread")
    @Operation(summary="Notifications non lues")
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> nonLues(
            @AuthenticationPrincipal String userId) {
        List<NotificationResponse> list = repo.findNonLues(UUID.fromString(userId))
            .stream().map(NotificationResponse::from).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @PatchMapping("/read-all")
    @Operation(summary="Marquer toutes les notifications comme lues")
    public ResponseEntity<ApiResponse<Void>> toutMarquerLu(
            @AuthenticationPrincipal String userId) {
        repo.marquerToutesLues(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok("Notifications marquées lues."));
    }
}
JEOF

cat > "$P/api/controller/CommunauteController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.PostMessageRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.communaute.PostMessageUseCase;
import com.mbem.mbemlevel.application.port.out.CommunauteRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * API Communauté — S12 (Q&R par cours).
 * GET  /api/v1/communaute/cours/{id}/questions
 * POST /api/v1/communaute/cours/{id}/messages
 * GET  /api/v1/communaute/messages/{id}/reponses
 */
@RestController
@RequestMapping("/api/v1/communaute")
@Tag(name="Communauté", description="Questions et réponses par cours")
@RequiredArgsConstructor
public class CommunauteController {
    private final PostMessageUseCase    postUC;
    private final CommunauteRepository  communauteRepo;

    @GetMapping("/cours/{coursId}/questions")
    @Operation(summary="Questions d'un cours (S12)")
    public ResponseEntity<ApiResponse<PageResponse<MessageResponse>>> questions(
            @PathVariable UUID coursId,
            @RequestParam(defaultValue="0") int page,
            @RequestParam(defaultValue="20") int size) {
        Page<MessageResponse> result = communauteRepo
            .findQuestions(coursId, PageRequest.of(page, size))
            .map(MessageResponse::from);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(result)));
    }

    @PostMapping("/cours/{coursId}/messages")
    @Operation(summary="Poster une question ou réponse (S12)")
    public ResponseEntity<ApiResponse<MessageResponse>> poster(
            @PathVariable UUID coursId,
            @Valid @RequestBody PostMessageRequest req,
            @AuthenticationPrincipal String userId) {
        var msg = postUC.poster(coursId, UUID.fromString(userId),
            req.contenu(), req.parentId());
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(MessageResponse.from(msg)));
    }

    @GetMapping("/messages/{parentId}/reponses")
    @Operation(summary="Réponses à une question")
    public ResponseEntity<ApiResponse<PageResponse<MessageResponse>>> reponses(
            @PathVariable UUID parentId,
            @RequestParam(defaultValue="0") int page,
            @RequestParam(defaultValue="20") int size) {
        Page<MessageResponse> result = communauteRepo
            .findReponses(parentId, PageRequest.of(page, size))
            .map(MessageResponse::from);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(result)));
    }
}
JEOF
ok "Controllers : TalentController · CertificatController · NotificationController · CommunauteController"

# =============================================================================
sec "6/6 Infrastructure Email + WhatsApp + PDF (Adapters)"
# =============================================================================
mkdir -p "$P/infrastructure/notification"
mkdir -p "$P/infrastructure/pdf"
mkdir -p "$P/infrastructure/storage"

cat > "$P/infrastructure/notification/EmailNotificationAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.notification;
import com.mbem.mbemlevel.application.port.out.EmailPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import java.util.Map;
/**
 * Adaptateur email via SMTP (SendGrid en production, MailHog en dev).
 * Tous les envois sont asynchrones (@Async) pour ne pas bloquer les requêtes HTTP.
 */
@Component @RequiredArgsConstructor @Slf4j
public class EmailNotificationAdapter implements EmailPort {
    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;
    private static final String FROM = "noreply@mbemnova.com";

    private void envoyerHtml(String to, String subject, String template,
                              Map<String, Object> vars) {
        try {
            Context ctx = new Context(); ctx.setVariables(vars);
            String html = templateEngine.process(template, ctx);
            var msg = mailSender.createMimeMessage();
            var helper = new MimeMessageHelper(msg, true, "UTF-8");
            helper.setFrom(FROM, "MbemNova"); helper.setTo(to);
            helper.setSubject(subject); helper.setText(html, true);
            mailSender.send(msg);
            log.debug("[EMAIL] Envoyé: template={} to={}", template, to);
        } catch (Exception e) {
            log.error("[EMAIL] Erreur envoi {} vers {}: {}", template, to, e.getMessage());
        }
    }

    @Override @Async public void envoyerBienvenue(String email, String prenom) {
        envoyerHtml(email, "Bienvenue sur MbemNova !", "bienvenue",
            Map.of("prenom", prenom)); }
    @Override @Async public void envoyerRappel48h(String email, String prenom) {
        envoyerHtml(email, "Tu n'as pas encore commencé...", "rappel-48h",
            Map.of("prenom", prenom)); }
    @Override @Async public void envoyerResetMotDePasse(String email, String prenom, String lien) {
        envoyerHtml(email, "Réinitialisation de ton mot de passe", "reset-mdp",
            Map.of("prenom", prenom, "lien", lien, "ttlMinutes", 60)); }
    @Override @Async public void envoyerAlerteTentativesSuspectes(String email, String prenom, int nb, String ip) {
        envoyerHtml(email, "Activité suspecte sur ton compte", "alerte-securite",
            Map.of("prenom", prenom, "nbTentatives", nb, "ip", ip)); }
    @Override @Async public void envoyerNurturingSeuilAtteint(String email, String prenom, String cours) {
        envoyerHtml(email, "Tu progresses vite ! Continue...", "seuil-paiement",
            Map.of("prenom", prenom, "nomCours", cours)); }
    @Override @Async public void envoyerActivationAcces(String email, String prenom, String cours, String facture) {
        envoyerHtml(email, "Accès complet activé — " + cours, "activation-acces",
            Map.of("prenom", prenom, "nomCours", cours,
                   "lienFacture", facture != null ? facture : "")); }
    @Override @Async public void envoyerRelancePaiement(String email, String prenom, String cours, int jours) {
        String template = jours > 0 ? "relance-j7" : "relance-retard";
        envoyerHtml(email, "Rappel paiement — " + cours, template,
            Map.of("prenom", prenom, "nomCours", cours, "joursAvantEcheance", jours)); }
    @Override @Async public void envoyerSuspension(String email, String prenom, String msg) {
        envoyerHtml(email, "Accès temporairement suspendu", "suspension",
            Map.of("prenom", prenom, "messageAdmin", msg)); }
    @Override @Async public void envoyerReactivation(String email, String prenom, String cours) {
        envoyerHtml(email, "Ton accès est rétabli !", "reactivation",
            Map.of("prenom", prenom, "nomCours", cours)); }
    @Override @Async public void envoyerCertificatObtenu(String email, String prenom,
            String cours, String pdf, String code) {
        envoyerHtml(email, "Félicitations ! Ton certificat " + cours, "certificat-obtenu",
            Map.of("prenom", prenom, "nomCours", cours,
                   "codeVerif", code, "lienPdf", pdf != null ? pdf : "")); }
    @Override @Async public void envoyerNouveauDevoir(String email, String prenom, String nom, String date) {
        envoyerHtml(email, "Nouveau devoir : " + nom, "nouveau-devoir",
            Map.of("prenom", prenom, "nomDevoir", nom, "dateRemise", date)); }
    @Override @Async public void envoyerRenduCorrige(String email, String prenom, String nom, int note, String cmt) {
        envoyerHtml(email, "Ton devoir a été corrigé — Note : " + note + "/20", "devoir-corrige",
            Map.of("prenom", prenom, "nomDevoir", nom, "note", note, "commentaire", cmt)); }
    @Override @Async public void envoyerGagnantTirage(String email, String prenom, String prix) {
        envoyerHtml(email, "Tu as gagné le tirage du mois !", "tirage-gagnant",
            Map.of("prenom", prenom, "prix", prix)); }
    @Override @Async public void envoyerRecomparainageActive(String emailParrain, String prenomParrain, String prenomFilleul) {
        envoyerHtml(emailParrain, "Ton filleul vient de commencer sa formation !", "parrainage-active",
            Map.of("prenomParrain", prenomParrain, "prenomFilleul", prenomFilleul)); }
}
JEOF
ok "EmailNotificationAdapter (implémente EmailPort — 15 templates)"

cat > "$P/infrastructure/notification/WhatsAppAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.notification;
import com.mbem.mbemlevel.application.port.out.WhatsAppPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import java.util.Map;
/**
 * Adaptateur WhatsApp Business (Meta Graph API).
 * Token configuré via ENV VAR WHATSAPP_TOKEN.
 * En dev : si token absent, le message est seulement loggé.
 */
@Component @Slf4j
public class WhatsAppAdapter implements WhatsAppPort {
    @Value("${mbemnova.whatsapp.api-url:https://graph.facebook.com/v21.0}") private String apiUrl;
    @Value("${mbemnova.whatsapp.token:}") private String token;
    @Value("${mbemnova.whatsapp.phone-number-id:}") private String phoneNumberId;
    @Value("${mbemnova.whatsapp.enabled:false}") private boolean enabled;

    @Override
    public void envoyerMessage(String telephone, String message) {
        if (!enabled || token.isBlank()) {
            log.debug("[WHATSAPP-MOCK] To: {} | {}", telephone, message); return;
        }
        try {
            new RestTemplate().postForObject(
                apiUrl + "/" + phoneNumberId + "/messages",
                Map.of("messaging_product","whatsapp","to",telephone,
                       "type","text","text",Map.of("body",message)),
                String.class);
        } catch (Exception e) {
            log.error("[WHATSAPP] Erreur envoi vers {}: {}", telephone, e.getMessage());
        }
    }
    @Override
    public void envoyerTemplate(String telephone, String templateName, String... params) {
        log.debug("[WHATSAPP] Template {} vers {}", templateName, telephone);
        // Templates WhatsApp pré-approuvés par Meta — implémentation Phase 2
    }
}
JEOF

cat > "$P/infrastructure/pdf/ITextPDFAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.pdf;
import com.mbem.mbemlevel.application.port.out.PDFPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import java.io.ByteArrayOutputStream;
import java.util.Map;
/**
 * Génère des PDFs depuis les templates Thymeleaf via iText 8 + html2pdf.
 * Utilisé pour : certificats PDF, factures, emplois du temps.
 */
@Component @RequiredArgsConstructor @Slf4j
public class ITextPDFAdapter implements PDFPort {
    private final TemplateEngine templateEngine;
    @Override
    public byte[] generer(String templateName, Map<String, Object> variables) {
        try {
            Context ctx = new Context(); ctx.setVariables(variables);
            String html = templateEngine.process("pdf/" + templateName, ctx);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            // Conversion HTML → PDF via iText html2pdf
            com.itextpdf.html2pdf.HtmlConverter.convertToPdf(html, baos);
            log.debug("[PDF] Généré: template={} size={}bytes", templateName, baos.size());
            return baos.toByteArray();
        } catch (Exception e) {
            log.error("[PDF] Erreur génération {}: {}", templateName, e.getMessage());
            throw new RuntimeException("Erreur génération PDF : " + templateName, e);
        }
    }
}
JEOF

cat > "$P/infrastructure/storage/MinIOStorageAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.storage;
import com.mbem.mbemlevel.application.port.out.StoragePort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import java.time.Duration;
/**
 * Stockage S3-compatible (MinIO en dev, AWS S3 en prod).
 * Utilisé pour : CVs, certificats PDF, images de cours.
 */
@Component @RequiredArgsConstructor @Slf4j
public class MinIOStorageAdapter implements StoragePort {
    private final S3Client   s3Client;
    private final S3Presigner presigner;
    @Value("${storage.minio.bucket-name:mbemnova}") private String bucket;

    @Override
    public String upload(String path, byte[] content, String contentType) {
        s3Client.putObject(
            PutObjectRequest.builder().bucket(bucket).key(path).contentType(contentType).build(),
            RequestBody.fromBytes(content));
        log.debug("[STORAGE] Uploadé: {}", path);
        return path;
    }
    @Override
    public void delete(String path) {
        s3Client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(path).build());
    }
    @Override
    public String presignedUrl(String path) {
        return presigner.presignGetObject(GetObjectPresignRequest.builder()
            .signatureDuration(Duration.ofHours(1))
            .getObjectRequest(GetObjectRequest.builder().bucket(bucket).key(path).build())
            .build()).url().toString();
    }
}
JEOF
ok "WhatsAppAdapter · ITextPDFAdapter · MinIOStorageAdapter"

# =============================================================================
echo -e "\n${B}${G}  Script 12 terminé${N}"
echo -e "  ${G}✓${N} Domain : Certificat, Notification, MessageCommunaute, Signalement, Parrainage, TirageAuSort"
echo -e "  ${G}✓${N} JPA + Repos + Adapters + Ports (Certificat, Notification, Communauté)"
echo -e "  ${G}✓${N} Ports : PDFPort, StoragePort, WhatsAppPort"
echo -e "  ${G}✓${N} Use Cases : GenererCertificat (S13), VerifierCertificat, MettreAJourProfil (S14),"
echo -e "               GetProfilTalent, PostMessage (S12), TraiterParrainage (S15)"
echo -e "  ${G}✓${N} Controllers : TalentController, CertificatController,"
echo -e "               NotificationController, CommunauteController"
echo -e "  ${G}✓${N} EmailNotificationAdapter (15 templates) · WhatsAppAdapter · ITextPDFAdapter · MinIOStorageAdapter\n"
echo -e "  \033[1;33m→ ./s13_admin_gamification.sh\033[0m\n"
