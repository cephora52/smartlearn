#!/usr/bin/env bash
# =============================================================================
# MbemNova — Script 02/15 : Arborescence complète du projet
# =============================================================================
# RÔLE   : Crée TOUS les dossiers et fichiers Java stub (vides documentés)
#          respectant l'architecture hexagonale.
#          Ne touche JAMAIS à un fichier existant.
#
# PRÉREQUIS : s01_pom_config.sh doit avoir été lancé
#
# USAGE  : chmod +x s02_structure.sh && ./s02_structure.sh
# =============================================================================

set -euo pipefail
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m';  C_BOLD='\033[1m';    C_NC='\033[0m'

log_ok()  { echo -e "${C_GREEN}  [OK]${C_NC} $1"; }
log_inf() { echo -e "${C_BLUE}  [..]${C_NC} $1"; }
log_sec() { echo -e "\n${C_BOLD}${C_CYAN}── $1 ──${C_NC}"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$ROOT/src/main/java/com/mbem/mbemlevel"
TEST_PKG="$ROOT/src/test/java/com/mbem/mbemlevel"
RES="$ROOT/src/main/resources"
TEST_RES="$ROOT/src/test/resources"

echo ""
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo -e "${C_BOLD}${C_CYAN}  MbemNova · Script 02/15 · Arborescence       ${C_NC}"
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo ""

[[ ! -f "$ROOT/pom.xml" ]] && { echo "ERREUR: lancez s01_pom_config.sh d'abord"; exit 1; }

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

# mk : crée un dossier s'il n'existe pas
mk() { mkdir -p "$1"; }

# stub_java : crée un fichier Java stub avec en-tête, ne remplace pas l'existant
# $1 = chemin complet
# $2 = package Java
# $3 = type (class/interface/record/enum)
# $4 = nom de la classe
# $5 = description courte
stub_java() {
  local file="$1" pkg="$2" type="$3" name="$4" desc="$5"
  [[ -f "$file" ]] && return 0   # Ne jamais écraser un fichier existant
  mkdir -p "$(dirname "$file")"
  cat > "$file" << JAVAEOF
// =============================================================================
// MbemNova — ${pkg}.${name}
// ${desc}
// TODO: Implémenté par script 0X/15
// =============================================================================
package ${pkg};

public ${type} ${name} {
    // TODO
}
JAVAEOF
}

# stub_interface : variante pour les interfaces
stub_interface() {
  local file="$1" pkg="$2" name="$3" desc="$4"
  [[ -f "$file" ]] && return 0
  mkdir -p "$(dirname "$file")"
  cat > "$file" << JAVAEOF
// =============================================================================
// MbemNova — ${pkg}.${name}
// ${desc}
// TODO: Implémenté par script 0X/15
// =============================================================================
package ${pkg};

public interface ${name} {
    // TODO
}
JAVAEOF
}

# stub_record : pour les Java Records
stub_record() {
  local file="$1" pkg="$2" name="$3" desc="$4"
  [[ -f "$file" ]] && return 0
  mkdir -p "$(dirname "$file")"
  printf '// MbemNova — %s.%s\n// %s\npackage %s;\npublic record %s() {}\n' \
    "$pkg" "$name" "$desc" "$pkg" "$name" > "$file"
}

# stub_enum : pour les enums
stub_enum() {
  local file="$1" pkg="$2" name="$3" desc="$4"
  [[ -f "$file" ]] && return 0
  mkdir -p "$(dirname "$file")"
  printf '// MbemNova — %s.%s\n// %s\npackage %s;\npublic enum %s { /* TODO */ }\n' \
    "$pkg" "$name" "$desc" "$pkg" "$name" > "$file"
}

# stub_sql : fichier SQL vide documenté
stub_sql() {
  local file="$1" desc="$2"
  [[ -f "$file" ]] && return 0
  mkdir -p "$(dirname "$file")"
  echo "-- MbemNova: $desc" > "$file"
  echo "-- TODO" >> "$file"
}

# stub_html : template Thymeleaf/HTML vide
stub_html() {
  local file="$1" title="$2"
  [[ -f "$file" ]] && return 0
  mkdir -p "$(dirname "$file")"
  printf '<!DOCTYPE html>\n<!-- MbemNova — %s -->\n<html xmlns:th="http://www.thymeleaf.org">\n<body>\n<!-- TODO -->\n</body>\n</html>\n' "$title" > "$file"
}

# stub_file : fichier texte générique
stub_file() {
  local file="$1" comment="$2" content="${3:-}"
  [[ -f "$file" ]] && return 0
  mkdir -p "$(dirname "$file")"
  printf '# MbemNova — %s\n%s\n' "$comment" "$content" > "$file"
}

TOTAL_FILES=0
count() { TOTAL_FILES=$((TOTAL_FILES + 1)); }

# =============================================================================
# SECTION 1 — COUCHE DOMAIN
# Zéro dépendance Spring/JPA — Java pur uniquement
# =============================================================================
log_sec "1/8 Couche Domain"
D="com.mbem.mbemlevel.domain"

# ── shared (primitives partagées) ─────────────────────────────────────────────
mk "$PKG/domain/shared/enums"
stub_java "$PKG/domain/shared/AggregateRoot.java"  "$D.shared" "class"     "AggregateRoot"     "Classe de base pour tous les agrégats — gère domain events"  ; count
stub_interface "$PKG/domain/shared/ValueObject.java" "$D.shared" "ValueObject" "Marqueur immuable pour les value objects"                ; count
stub_java "$PKG/domain/shared/Money.java"           "$D.shared" "class"     "Money"             "Value Object — montant monétaire en FCFA (XAF), immuable"    ; count
stub_java "$PKG/domain/shared/Email.java"           "$D.shared" "class"     "Email"             "Value Object — adresse email validée"                         ; count
stub_enum "$PKG/domain/shared/enums/Role.java"      "$D.shared.enums" "Role"      "APPRENANT FORMATEUR ADMIN SUPER_ADMIN"                       ; count
stub_enum "$PKG/domain/shared/enums/StatutApprenant.java"    "$D.shared.enums" "StatutApprenant"    "INSCRIT ACTIF SUSPENDU CERTIFIE"          ; count
stub_enum "$PKG/domain/shared/enums/StatutPaiement.java"     "$D.shared.enums" "StatutPaiement"     "EN_ATTENTE PAYE EN_RETARD MORATOIRE"      ; count
stub_enum "$PKG/domain/shared/enums/ModePaiement.java"       "$D.shared.enums" "ModePaiement"       "CASH MOBILE_MONEY ONLINE"                ; count
stub_enum "$PKG/domain/shared/enums/NiveauCours.java"        "$D.shared.enums" "NiveauCours"        "DEBUTANT INTERMEDIAIRE AVANCE"            ; count
stub_enum "$PKG/domain/shared/enums/Modalite.java"           "$D.shared.enums" "Modalite"           "PRESENTIEL ONLINE_MEET"                   ; count
stub_enum "$PKG/domain/shared/enums/CanalNotification.java"  "$D.shared.enums" "CanalNotification"  "EMAIL WHATSAPP IN_APP"                    ; count
stub_enum "$PKG/domain/shared/enums/TypeNotification.java"   "$D.shared.enums" "TypeNotification"   "RAPPEL BADGE RELANCE DEVOIR CERTIFICAT"   ; count

# ── domain events ─────────────────────────────────────────────────────────────
mk "$PKG/domain/event"
stub_interface "$PKG/domain/event/DomainEvent.java"              "$D.event" "DomainEvent"              "Interface marqueur pour tous les domain events"    ; count
stub_record    "$PKG/domain/event/ApprenantInscritEvent.java"    "$D.event" "ApprenantInscritEvent"    "Nouvel apprenant inscrit"                          ; count
stub_record    "$PKG/domain/event/SeuilPaiementAtteintEvent.java" "$D.event" "SeuilPaiementAtteintEvent" "Seuil de conversion atteint"                   ; count
stub_record    "$PKG/domain/event/PaiementConfirmeEvent.java"    "$D.event" "PaiementConfirmeEvent"    "Paiement confirmé par admin"                       ; count
stub_record    "$PKG/domain/event/CoursTermineEvent.java"        "$D.event" "CoursTermineEvent"        "Toutes leçons et QCM validés"                     ; count
stub_record    "$PKG/domain/event/CertificatObtenuEvent.java"    "$D.event" "CertificatObtenuEvent"    "Certificat généré"                                 ; count
stub_record    "$PKG/domain/event/PaiementEnRetardEvent.java"    "$D.event" "PaiementEnRetardEvent"    "Échéance dépassée"                                ; count
stub_record    "$PKG/domain/event/CompteSuspenduEvent.java"      "$D.event" "CompteSuspenduEvent"      "Compte suspendu J+10"                              ; count
stub_record    "$PKG/domain/event/CompteReactiveEvent.java"      "$D.event" "CompteReactiveEvent"      "Compte réactivé après régularisation"             ; count
stub_record    "$PKG/domain/event/DevoirPublieEvent.java"        "$D.event" "DevoirPublieEvent"        "Formateur a publié un devoir"                      ; count
stub_record    "$PKG/domain/event/RenduCorrigeEvent.java"        "$D.event" "RenduCorrigeEvent"        "Formateur a noté le rendu"                         ; count
stub_record    "$PKG/domain/event/ParrainageActiveEvent.java"    "$D.event" "ParrainageActiveEvent"    "Filleul a complété son premier module"             ; count

# ── user ──────────────────────────────────────────────────────────────────────
mk "$PKG/domain/user/valueobject"
stub_java "$PKG/domain/user/Utilisateur.java"                   "$D.user" "class" "Utilisateur"    "Agrégat racine — base commune de tous les utilisateurs"      ; count
stub_java "$PKG/domain/user/Apprenant.java"                     "$D.user" "class" "Apprenant"      "Apprenant — xp streak rang disponibilite"                    ; count
stub_java "$PKG/domain/user/Formateur.java"                     "$D.user" "class" "Formateur"      "Formateur — specialite biographie noteGlobale"               ; count
stub_java "$PKG/domain/user/Admin.java"                         "$D.user" "class" "Admin"          "Administrateur — niveauAcces"                                ; count
stub_java "$PKG/domain/user/UserDomainService.java"             "$D.user" "class" "UserDomainService" "Règles métier liées aux utilisateurs"                    ; count
stub_java "$PKG/domain/user/valueobject/ProfilTalent.java"      "$D.user.valueobject" "class" "ProfilTalent"  "Value Object — profil public apprenant"         ; count
stub_java "$PKG/domain/user/valueobject/LienParrainage.java"    "$D.user.valueobject" "class" "LienParrainage" "Value Object — code parrainage et filleuls"    ; count

# ── cours ─────────────────────────────────────────────────────────────────────
mk "$PKG/domain/cours"
stub_java "$PKG/domain/cours/Cours.java"             "$D.cours" "class" "Cours"            "Agrégat cours — titre categorie seuilPaiement"        ; count
stub_java "$PKG/domain/cours/Module.java"            "$D.cours" "class" "Module"           "Module — ordre estVerrouille"                         ; count
stub_java "$PKG/domain/cours/Lecon.java"             "$D.cours" "class" "Lecon"            "Leçon — contenu lienPDF lienVideo duree"              ; count
stub_java "$PKG/domain/cours/QCM.java"               "$D.cours" "class" "QCM"              "QCM — question options bonneReponse estObligatoire"   ; count
stub_java "$PKG/domain/cours/Categorie.java"         "$D.cours" "class" "Categorie"        "Catégorie cours — nom description"                   ; count
stub_java "$PKG/domain/cours/CoursDomainService.java" "$D.cours" "class" "CoursDomainService" "Règles seuil déverrouillage modules"              ; count

# ── progression ───────────────────────────────────────────────────────────────
mk "$PKG/domain/progression"
stub_java "$PKG/domain/progression/Progression.java"              "$D.progression" "class" "Progression"         "Agrégat — pourcentage estPaye xp dateDebut"      ; count
stub_java "$PKG/domain/progression/ReponseQCM.java"               "$D.progression" "class" "ReponseQCM"          "Réponse QCM — estCorrecte score tentatives"      ; count
stub_java "$PKG/domain/progression/Badge.java"                    "$D.progression" "class" "Badge"               "Badge gamification"                               ; count
stub_java "$PKG/domain/progression/ProgressionDomainService.java" "$D.progression" "class" "ProgressionDomainService" "Calcul pct XP streak badges"               ; count

# ── paiement ──────────────────────────────────────────────────────────────────
mk "$PKG/domain/paiement"
stub_java "$PKG/domain/paiement/Paiement.java"            "$D.paiement" "class" "Paiement"            "Agrégat — montant statut mode echeance"           ; count
stub_java "$PKG/domain/paiement/Tranche.java"             "$D.paiement" "class" "Tranche"             "Tranche — numero montant dates"                   ; count
stub_java "$PKG/domain/paiement/Facture.java"             "$D.paiement" "class" "Facture"             "Facture — codeVerif dateEmission lienPDF"         ; count
stub_java "$PKG/domain/paiement/Moratoire.java"           "$D.paiement" "class" "Moratoire"           "Moratoire — raison nouvelleDateEcheance statut"   ; count
stub_java "$PKG/domain/paiement/PaiementDomainService.java" "$D.paiement" "class" "PaiementDomainService" "Règles retards et moratoire"                 ; count

# ── session ───────────────────────────────────────────────────────────────────
mk "$PKG/domain/session"
stub_java "$PKG/domain/session/Session.java"              "$D.session" "class" "Session"             "Agrégat — dates modalite capaciteMax formateur"   ; count
stub_java "$PKG/domain/session/Creneau.java"              "$D.session" "class" "Creneau"             "Créneau — jour heure duree placesRestantes"      ; count
stub_java "$PKG/domain/session/Devoir.java"               "$D.session" "class" "Devoir"              "Devoir — consignes dateRemise module"              ; count
stub_java "$PKG/domain/session/Rendu.java"                "$D.session" "class" "Rendu"               "Rendu — apprenant contenu note"                   ; count
stub_java "$PKG/domain/session/SessionDomainService.java" "$D.session" "class" "SessionDomainService" "Détection conflits horaires"                    ; count

# ── communaute ────────────────────────────────────────────────────────────────
mk "$PKG/domain/communaute"
stub_java "$PKG/domain/communaute/MessageCommunaute.java" "$D.communaute" "class" "MessageCommunaute" "Message Q&R — auteur cours contenu"              ; count
stub_java "$PKG/domain/communaute/Signalement.java"       "$D.communaute" "class" "Signalement"       "Signalement — message auteur raison statut"      ; count

# ── certificat ────────────────────────────────────────────────────────────────
mk "$PKG/domain/certificat"
stub_java "$PKG/domain/certificat/Certificat.java"              "$D.certificat" "class" "Certificat"           "Agrégat — codeVerification dateEmission"          ; count
stub_java "$PKG/domain/certificat/CertificatDomainService.java" "$D.certificat" "class" "CertificatDomainService" "Validation conditions obtention"              ; count

# ── notification ──────────────────────────────────────────────────────────────
mk "$PKG/domain/notification"
stub_java "$PKG/domain/notification/Notification.java"    "$D.notification" "class" "Notification"    "Notification in-app — type canal contenu estLue"  ; count

# ── gamification ──────────────────────────────────────────────────────────────
mk "$PKG/domain/gamification"
stub_java "$PKG/domain/gamification/TirageAuSort.java" "$D.gamification" "class" "TirageAuSort" "Tirage mensuel — participants gagnants"              ; count
stub_java "$PKG/domain/gamification/Parrainage.java"   "$D.gamification" "class" "Parrainage"   "Parrainage — parrain filleul statut recompense"      ; count

log_ok "Couche Domain : $TOTAL_FILES fichiers"
D_COUNT=$TOTAL_FILES; TOTAL_FILES=0

# =============================================================================
# SECTION 2 — COUCHE APPLICATION
# Use cases, CQRS, Ports (interfaces)
# =============================================================================
log_sec "2/8 Couche Application"
A="com.mbem.mbemlevel.application"

# ── Ports entrants (interfaces use cases) ─────────────────────────────────────
mk "$PKG/application/port/in"
for uc in Auth Cours Progression Paiement Session Talent Admin Communaute Gamification; do
  stub_interface "$PKG/application/port/in/${uc}UseCase.java" "$A.port.in" "${uc}UseCase" "Port entrant — contrat use case $uc"; count
done

# ── Ports sortants (interfaces vers infra) ────────────────────────────────────
mk "$PKG/application/port/out"
for repo in Utilisateur Apprenant Formateur Cours Progression Paiement Session Certificat Notification Communaute RefreshToken ResetToken AuditLog; do
  stub_interface "$PKG/application/port/out/${repo}Repository.java" "$A.port.out" "${repo}Repository" "Port sortant — persistance $repo"; count
done
stub_interface "$PKG/application/port/out/EmailPort.java"   "$A.port.out" "EmailPort"   "Port sortant — envoi emails"; count
stub_interface "$PKG/application/port/out/WhatsAppPort.java" "$A.port.out" "WhatsAppPort" "Port sortant — envoi WhatsApp"; count
stub_interface "$PKG/application/port/out/PDFPort.java"     "$A.port.out" "PDFPort"     "Port sortant — génération PDF"; count
stub_interface "$PKG/application/port/out/StoragePort.java" "$A.port.out" "StoragePort" "Port sortant — stockage fichiers S3/MinIO"; count
stub_interface "$PKG/application/port/out/CachePort.java"   "$A.port.out" "CachePort"   "Port sortant — cache Redis"; count

# ── Use cases Auth ────────────────────────────────────────────────────────────
mk "$PKG/application/usecase/auth"
for uc in InscrireApprenant ConnecterUtilisateur RefreshToken Deconnecter ReinitialiserMotDePasse ConfirmerEmail; do
  stub_java "$PKG/application/usecase/auth/${uc}UseCase.java" "$A.usecase.auth" "class" "${uc}UseCase" "Use case Auth — $uc"; count
done

# ── Use cases Cours ───────────────────────────────────────────────────────────
mk "$PKG/application/usecase/cours"
for uc in GetCatalogue GetDetailCours CreerCours ModifierCours PublierCours DesactiverCours; do
  stub_java "$PKG/application/usecase/cours/${uc}UseCase.java" "$A.usecase.cours" "class" "${uc}UseCase" "Use case Cours — $uc"; count
done

# ── Use cases Progression ─────────────────────────────────────────────────────
mk "$PKG/application/usecase/progression"
for uc in CommencerCours TerminerLecon ValiderQCM GetProgression VerifierSeuilPaiement; do
  stub_java "$PKG/application/usecase/progression/${uc}UseCase.java" "$A.usecase.progression" "class" "${uc}UseCase" "Use case Progression — $uc"; count
done

# ── Use cases Paiement ────────────────────────────────────────────────────────
mk "$PKG/application/usecase/paiement"
for uc in EnregistrerPaiementCash ActiverAcces DemanderMoratoire TraiterMoratoire SuspendreCompte ReactiverCompte GetPaiementsEnRetard; do
  stub_java "$PKG/application/usecase/paiement/${uc}UseCase.java" "$A.usecase.paiement" "class" "${uc}UseCase" "Use case Paiement — $uc"; count
done

# ── Use cases Session ─────────────────────────────────────────────────────────
mk "$PKG/application/usecase/session"
for uc in CreerSession InscrireApprenantSession GenererEmploiDuTemps EnvoyerDevoir SoumettreRendu CorrigerRendu; do
  stub_java "$PKG/application/usecase/session/${uc}UseCase.java" "$A.usecase.session" "class" "${uc}UseCase" "Use case Session — $uc"; count
done

# ── Use cases Talent ──────────────────────────────────────────────────────────
mk "$PKG/application/usecase/talent"
for uc in MettreAJourProfil GetProfilTalent GenererCertificat VerifierCertificat UploadCV; do
  stub_java "$PKG/application/usecase/talent/${uc}UseCase.java" "$A.usecase.talent" "class" "${uc}UseCase" "Use case Talent — $uc"; count
done

# ── Use cases Admin ───────────────────────────────────────────────────────────
mk "$PKG/application/usecase/admin"
for uc in InscrireApprenantManuel AssignerRole GetStatistiques GetAlertesPrioritaires ExporterDonnees GererCommunaute; do
  stub_java "$PKG/application/usecase/admin/${uc}UseCase.java" "$A.usecase.admin" "class" "${uc}UseCase" "Use case Admin — $uc"; count
done

# ── Use cases Gamification ────────────────────────────────────────────────────
mk "$PKG/application/usecase/gamification"
stub_java "$PKG/application/usecase/gamification/EffectuerTirageAuSortUseCase.java" "$A.usecase.gamification" "class" "EffectuerTirageAuSortUseCase" "Tirage mensuel"; count
stub_java "$PKG/application/usecase/gamification/TraiterParrainageUseCase.java"     "$A.usecase.gamification" "class" "TraiterParrainageUseCase"     "Activer récompense parrainage"; count

# ── Queries CQRS (lecture seule) ──────────────────────────────────────────────
mk "$PKG/application/query"
for q in GetDashboardApprenant GetCatalogue GetProgression GetDashboardAdmin GetTalents GetSessionsDisponibles; do
  stub_java "$PKG/application/query/${q}Query.java" "$A.query" "class" "${q}Query" "Query CQRS — $q (read-only)"; count
done

# ── Event Handlers ────────────────────────────────────────────────────────────
mk "$PKG/application/event"
for h in ApprenantInscrit SeuilAtteint PaiementConfirme CertificatObtenu PaiementEnRetard CompteSuspendu DevoirPublie RenduCorrige; do
  stub_java "$PKG/application/event/${h}Handler.java" "$A.event" "class" "${h}Handler" "Handler domain event — $h"; count
done

# ── DTOs Application (Commands + Responses) ───────────────────────────────────
mk "$PKG/application/dto/request"
mk "$PKG/application/dto/response"
for cmd in Inscription Connexion Paiement Moratoire Session Devoir; do
  stub_record "$PKG/application/dto/request/${cmd}Command.java" "$A.dto.request" "${cmd}Command" "Command — données $cmd"; count
done
for dto in Apprenant Cours Progression Paiement Statistiques Dashboard; do
  stub_record "$PKG/application/dto/response/${dto}Dto.java" "$A.dto.response" "${dto}Dto" "DTO réponse — $dto"; count
done
stub_record "$PKG/application/dto/response/AuthResultDto.java" "$A.dto.response" "AuthResultDto" "Résultat authentification — JWT + refreshToken"; count

# ── Mappers Application ───────────────────────────────────────────────────────
mk "$PKG/application/mapper"
for m in Apprenant Cours Paiement; do
  stub_interface "$PKG/application/mapper/${m}Mapper.java" "$A.mapper" "${m}Mapper" "MapStruct — Domain ↔ DTO $m"; count
done

log_ok "Couche Application : $TOTAL_FILES fichiers"
A_COUNT=$TOTAL_FILES; TOTAL_FILES=0

# =============================================================================
# SECTION 3 — COUCHE INFRASTRUCTURE
# Implémentations des ports (JPA, Redis, Email, PDF, Storage)
# =============================================================================
log_sec "3/8 Couche Infrastructure"
I="com.mbem.mbemlevel.infrastructure"

# ── JPA Entities ──────────────────────────────────────────────────────────────
mk "$PKG/infrastructure/persistence/entity"
for e in Utilisateur Apprenant Formateur Admin Cours Module Lecon QCM Categorie Progression ReponseQCM Paiement Tranche Facture Session Creneau Devoir Rendu Certificat Notification MessageCommunaute RefreshToken ResetToken AuditLog; do
  stub_java "$PKG/infrastructure/persistence/entity/${e}JpaEntity.java" "$I.persistence.entity" "class" "${e}JpaEntity" "@Entity — table $(echo "$e" | tr '[:upper:]' '[:lower:]')s"; count
done

# ── JPA Repositories ──────────────────────────────────────────────────────────
mk "$PKG/infrastructure/persistence/repository"
for r in Utilisateur Cours Progression Paiement Session Devoir Certificat Notification MessageCommunaute RefreshToken ResetToken AuditLog; do
  stub_interface "$PKG/infrastructure/persistence/repository/${r}JpaRepository.java" "$I.persistence.repository" "${r}JpaRepository" "extends JpaRepository — $r"; count
done

# ── Adapters (implémentent les ports) ─────────────────────────────────────────
mk "$PKG/infrastructure/persistence/adapter"
for a in Utilisateur Cours Progression Paiement Session Certificat Notification RefreshToken ResetToken AuditLog; do
  stub_java "$PKG/infrastructure/persistence/adapter/${a}RepositoryAdapter.java" "$I.persistence.adapter" "class" "${a}RepositoryAdapter" "@Component — implémente ${a}Repository"; count
done

# ── Mappers JPA ↔ Domain ──────────────────────────────────────────────────────
mk "$PKG/infrastructure/persistence/mapper"
for m in Utilisateur Cours Progression Paiement Session; do
  stub_interface "$PKG/infrastructure/persistence/mapper/${m}JpaMapper.java" "$I.persistence.mapper" "${m}JpaMapper" "@Mapper MapStruct — JpaEntity ↔ Domain $m"; count
done

# ── Cache Redis ───────────────────────────────────────────────────────────────
mk "$PKG/infrastructure/cache"
stub_java      "$PKG/infrastructure/cache/RedisCacheAdapter.java"  "$I.cache" "class" "RedisCacheAdapter"  "@Component — implémente CachePort via RedisTemplate"   ; count
stub_java      "$PKG/infrastructure/cache/RedisConfig.java"        "$I.cache" "class" "RedisConfig"        "@Configuration Redis — connexion pool sérialisation JSON"; count
stub_java      "$PKG/infrastructure/cache/CacheKeyConstants.java"  "$I.cache" "class" "CacheKeyConstants"  "Constantes clés Redis centralisées"                     ; count

# ── Sécurité JWT ──────────────────────────────────────────────────────────────
mk "$PKG/infrastructure/security/token"
stub_java "$PKG/infrastructure/security/token/JwtTokenProvider.java"          "$I.security.token" "class" "JwtTokenProvider"          "Génération/validation JWT Nimbus JOSE HS256"           ; count
stub_java "$PKG/infrastructure/security/token/TokenBlacklistService.java"     "$I.security.token" "class" "TokenBlacklistService"     "Blacklist JWT via Redis TTL"                           ; count
stub_java "$PKG/infrastructure/security/token/RefreshTokenService.java"       "$I.security.token" "class" "RefreshTokenService"       "Rotation refresh tokens — SHA-256 + blacklist"         ; count
stub_java "$PKG/infrastructure/security/token/ResetPasswordTokenService.java" "$I.security.token" "class" "ResetPasswordTokenService" "Tokens reset MDP — usage unique TTL 1h"                ; count

# ── Notification ──────────────────────────────────────────────────────────────
mk "$PKG/infrastructure/notification"
mk "$RES/templates/email"
stub_java  "$PKG/infrastructure/notification/SendGridEmailAdapter.java"    "$I.notification" "class" "SendGridEmailAdapter"    "@Component — implémente EmailPort via SMTP/SendGrid"   ; count
stub_java  "$PKG/infrastructure/notification/WhatsAppBusinessAdapter.java" "$I.notification" "class" "WhatsAppBusinessAdapter" "@Component — implémente WhatsAppPort via Meta API"     ; count
stub_java  "$PKG/infrastructure/notification/NotificationService.java"     "$I.notification" "class" "NotificationService"     "Orchestre email + WhatsApp + in-app"                   ; count
# Templates emails
for tmpl in bienvenue rappel-48h seuil-paiement activation-acces facture relance-j7 relance-j3 relance-retard suspension reactivation certificat-obtenu reset-mdp alerte-securite nouveau-devoir devoir-corrige tirage-gagnant parrainage-active; do
  stub_html "$RES/templates/email/${tmpl}.html" "Template email MbemNova — $tmpl"; count
done

# ── PDF ───────────────────────────────────────────────────────────────────────
mk "$PKG/infrastructure/pdf"
mk "$RES/templates/pdf"
stub_java "$PKG/infrastructure/pdf/ITextPDFAdapter.java"  "$I.pdf" "class" "ITextPDFAdapter"  "@Component — implémente PDFPort avec iText 8"; count
stub_java "$PKG/infrastructure/pdf/PDFTemplateConfig.java" "$I.pdf" "class" "PDFTemplateConfig" "@Configuration — chemin polices logo"; count
stub_html "$RES/templates/pdf/certificat.html"  "Template PDF certificat MbemNova"; count
stub_html "$RES/templates/pdf/facture.html"     "Template PDF facture MbemNova"; count
stub_html "$RES/templates/pdf/emploi-du-temps.html" "Template PDF emploi du temps"; count

# ── Storage ───────────────────────────────────────────────────────────────────
mk "$PKG/infrastructure/storage"
stub_java "$PKG/infrastructure/storage/MinIOStorageAdapter.java" "$I.storage" "class" "MinIOStorageAdapter" "@Component — implémente StoragePort MinIO S3"; count
stub_java "$PKG/infrastructure/storage/StorageConfig.java"       "$I.storage" "class" "StorageConfig"       "@Configuration MinIO — endpoint bucket region"; count

# ── Audit ─────────────────────────────────────────────────────────────────────
mk "$PKG/infrastructure/audit"
stub_java "$PKG/infrastructure/audit/AuditLogService.java" "$I.audit" "class" "AuditLogService" "@Service — log toutes actions sensibles (REQUIRES_NEW)"; count
stub_java "$PKG/infrastructure/audit/AuditEvent.java"      "$I.audit" "class" "AuditEvent"      "Modèle événement audit — qui quoi quand sur quoi"; count

# ── Schedulers ────────────────────────────────────────────────────────────────
mk "$PKG/infrastructure/scheduler"
stub_java "$PKG/infrastructure/scheduler/RelancePaiementScheduler.java" "$I.scheduler" "class" "RelancePaiementScheduler" "@Scheduled — relances J-7 J-3 J0 J+3 J+7 J+10"; count
stub_java "$PKG/infrastructure/scheduler/TirageAuSortScheduler.java"    "$I.scheduler" "class" "TirageAuSortScheduler"    "@Scheduled — tirage mensuel 1er du mois 08h00"; count
stub_java "$PKG/infrastructure/scheduler/RappelCoursScheduler.java"     "$I.scheduler" "class" "RappelCoursScheduler"     "@Scheduled — rappel 48h sans activité"; count
stub_java "$PKG/infrastructure/scheduler/SuspensionScheduler.java"      "$I.scheduler" "class" "SuspensionScheduler"      "@Scheduled — alerte admin J+10 sans paiement"; count
stub_java "$PKG/infrastructure/scheduler/CleanupTokenScheduler.java"    "$I.scheduler" "class" "CleanupTokenScheduler"    "@Scheduled — nettoyage tokens expirés et révoqués"; count
count; count; count; count; count  # 5 schedulers déjà comptés

# ── Configuration Infrastructure ──────────────────────────────────────────────
mk "$PKG/infrastructure/config"
stub_java "$PKG/infrastructure/config/JpaConfig.java"      "$I.config" "class" "JpaConfig"      "@Configuration — auditing @CreatedDate @LastModifiedDate"; count
stub_java "$PKG/infrastructure/config/FlywayConfig.java"   "$I.config" "class" "FlywayConfig"   "@Configuration — validation baseline migrations"; count
stub_java "$PKG/infrastructure/config/SchedulerConfig.java" "$I.config" "class" "SchedulerConfig" "@Configuration — thread pool timezone Africa/Douala"; count

log_ok "Couche Infrastructure : $TOTAL_FILES fichiers"
I_COUNT=$TOTAL_FILES; TOTAL_FILES=0

# =============================================================================
# SECTION 4 — COUCHE API (adaptateurs entrants)
# Controllers, Security, Filters, DTOs HTTP
# =============================================================================
log_sec "4/8 Couche API"
API="com.mbem.mbemlevel.api"

# ── Configuration sécurité ────────────────────────────────────────────────────
mk "$PKG/api/config"
stub_java "$PKG/api/config/SecurityConfig.java"          "$API.config" "class" "SecurityConfig"         "@Configuration @EnableWebSecurity — filterChain complet"; count
stub_java "$PKG/api/config/JwtConfig.java"               "$API.config" "class" "JwtConfig"              "@ConfigurationProperties — secret expiration rotation"; count
stub_java "$PKG/api/config/RateLimitConfig.java"         "$API.config" "class" "RateLimitConfig"        "@Configuration Bucket4j — limites par IP/endpoint"; count
stub_java "$PKG/api/config/OpenApiConfig.java"           "$API.config" "class" "OpenApiConfig"          "@Configuration SpringDoc — Swagger UI avec auth JWT"; count
stub_java "$PKG/api/config/WebConfig.java"               "$API.config" "class" "WebConfig"              "@Configuration CORS — origins methods headers credentials"; count
stub_java "$PKG/api/config/ApplicationConfig.java"       "$API.config" "class" "ApplicationConfig"      "@Configuration — beans partagés PasswordEncoder Clock"; count
stub_java "$PKG/api/config/ActuatorSecurityConfig.java"  "$API.config" "class" "ActuatorSecurityConfig" "@Configuration — sécurisation endpoints Actuator"; count

# ── Filtres HTTP ──────────────────────────────────────────────────────────────
mk "$PKG/api/filter"
stub_java "$PKG/api/filter/JwtAuthenticationFilter.java" "$API.filter" "class" "JwtAuthenticationFilter" "OncePerRequestFilter — extrait valide JWT Bearer"; count
stub_java "$PKG/api/filter/RateLimitFilter.java"         "$API.filter" "class" "RateLimitFilter"         "OncePerRequestFilter — Bucket4j IP throttling"; count
stub_java "$PKG/api/filter/RequestLoggingFilter.java"    "$API.filter" "class" "RequestLoggingFilter"    "OncePerRequestFilter — MDC requestId userId method path"; count
stub_java "$PKG/api/filter/SecurityHeadersFilter.java"   "$API.filter" "class" "SecurityHeadersFilter"   "OncePerRequestFilter — headers sécurité supplémentaires"; count

# ── Sécurité ──────────────────────────────────────────────────────────────────
mk "$PKG/api/security"
stub_java "$PKG/api/security/UserDetailsServiceImpl.java"    "$API.security" "class" "UserDetailsServiceImpl"    "implements UserDetailsService — charge par email"; count
stub_java "$PKG/api/security/CustomAuthEntryPoint.java"      "$API.security" "class" "CustomAuthEntryPoint"      "implements AuthenticationEntryPoint — 401 JSON"; count
stub_java "$PKG/api/security/CustomAccessDeniedHandler.java" "$API.security" "class" "CustomAccessDeniedHandler" "implements AccessDeniedHandler — 403 JSON"; count

# ── Controllers ───────────────────────────────────────────────────────────────
mk "$PKG/api/controller"
for ctrl in Auth Cours Progression Paiement Session Devoir Communaute Talent Certificat Notification Admin Health; do
  stub_java "$PKG/api/controller/${ctrl}Controller.java" "$API.controller" "class" "${ctrl}Controller" "@RestController @RequestMapping — endpoints $ctrl"; count
done

# ── DTOs HTTP Request ──────────────────────────────────────────────────────────
mk "$PKG/api/dto/request"
for req in Inscription Connexion RefreshToken ResetPassword NouveauMotDePasse CreerCours EnregistrerPaiement Moratoire CreerSession Devoir Rendu Correction Message ProfilUpdate AssignerRole; do
  stub_record "$PKG/api/dto/request/${req}Request.java" "$API.dto.request" "${req}Request" "Request HTTP — validé par Bean Validation"; count
done

# ── DTOs HTTP Response ────────────────────────────────────────────────────────
mk "$PKG/api/dto/response"
stub_record "$PKG/api/dto/response/ApiResponse.java"          "$API.dto.response" "ApiResponse"          "Wrapper universel — success data message timestamp"; count
stub_record "$PKG/api/dto/response/PageResponse.java"         "$API.dto.response" "PageResponse"         "Pagination — content page size totalElements"; count
stub_record "$PKG/api/dto/response/ErrorResponse.java"        "$API.dto.response" "ErrorResponse"        "Erreur — status code message details timestamp"; count
stub_record "$PKG/api/dto/response/AuthResponse.java"         "$API.dto.response" "AuthResponse"         "Auth — accessToken refreshToken user expiresAt"; count
stub_record "$PKG/api/dto/response/CoursResponse.java"        "$API.dto.response" "CoursResponse"        "Cours — données complètes catalogue"; count
stub_record "$PKG/api/dto/response/ProgressionResponse.java"  "$API.dto.response" "ProgressionResponse"  "Progression — pct modules XP streak badges"; count
stub_record "$PKG/api/dto/response/PaiementResponse.java"     "$API.dto.response" "PaiementResponse"     "Paiement — tranches statuts échéances"; count
stub_record "$PKG/api/dto/response/SessionResponse.java"      "$API.dto.response" "SessionResponse"      "Session — détails créneaux inscrits"; count
stub_record "$PKG/api/dto/response/ProfilTalentResponse.java" "$API.dto.response" "ProfilTalentResponse" "Profil public — certifications stack disponibilité"; count
stub_record "$PKG/api/dto/response/StatistiquesResponse.java" "$API.dto.response" "StatistiquesResponse" "Stats admin — revenus apprenants alertes"; count
stub_record "$PKG/api/dto/response/DashboardResponse.java"    "$API.dto.response" "DashboardResponse"    "Dashboard — agrégat selon le rôle"; count

# ── Exceptions ────────────────────────────────────────────────────────────────
mk "$PKG/api/exception"
stub_java "$PKG/api/exception/GlobalExceptionHandler.java"         "$API.exception" "class" "GlobalExceptionHandler"         "@RestControllerAdvice — toutes les exceptions → JSON"; count
stub_java "$PKG/api/exception/MbemNovaException.java"              "$API.exception" "class" "MbemNovaException"              "Exception de base avec code HTTP et errorCode"; count
stub_java "$PKG/api/exception/EmailDejaUtiliseException.java"      "$API.exception" "class" "EmailDejaUtiliseException"      "409 — EMAIL_ALREADY_EXISTS"; count
stub_java "$PKG/api/exception/TokenExpireException.java"           "$API.exception" "class" "TokenExpireException"           "401 — TOKEN_EXPIRED"; count
stub_java "$PKG/api/exception/CompteSuspenduException.java"        "$API.exception" "class" "CompteSuspenduException"        "403 — ACCOUNT_SUSPENDED"; count
stub_java "$PKG/api/exception/RessourceIntrouvableException.java"  "$API.exception" "class" "RessourceIntrouvableException"  "404 — RESOURCE_NOT_FOUND"; count
stub_java "$PKG/api/exception/AccesInterditException.java"         "$API.exception" "class" "AccesInterditException"         "403 — ACCESS_DENIED"; count
stub_java "$PKG/api/exception/SeuilPaiementException.java"         "$API.exception" "class" "SeuilPaiementException"         "402 — PAYMENT_REQUIRED"; count
stub_java "$PKG/api/exception/RateLimitException.java"             "$API.exception" "class" "RateLimitException"             "429 — RATE_LIMIT_EXCEEDED"; count
stub_java "$PKG/api/exception/FichierInvalideException.java"       "$API.exception" "class" "FichierInvalideException"       "400 — INVALID_FILE"; count

# ── Aspects AOP ───────────────────────────────────────────────────────────────
mk "$PKG/api/aspect"
stub_java "$PKG/api/aspect/AuditTrailAspect.java"  "$API.aspect" "class" "AuditTrailAspect"  "@Aspect — log audit toutes actions sensibles"; count
stub_java "$PKG/api/aspect/PerformanceAspect.java" "$API.aspect" "class" "PerformanceAspect" "@Aspect — alerte si endpoint dépasse 500ms"; count
stub_java "$PKG/api/aspect/SecurityAspect.java"    "$API.aspect" "class" "SecurityAspect"    "@Aspect — RBAC fin sur méthodes sensibles"; count

# ── Validators ────────────────────────────────────────────────────────────────
mk "$PKG/api/validator"
stub_java "$PKG/api/validator/MotDePasseValidator.java" "$API.validator" "class" "MotDePasseValidator" "Custom @Constraint — complexité mot de passe"; count
stub_java "$PKG/api/validator/FichierValidator.java"    "$API.validator" "class" "FichierValidator"    "Custom @Constraint — type MIME taille max 50Mo"; count

log_ok "Couche API : $TOTAL_FILES fichiers"
API_COUNT=$TOTAL_FILES; TOTAL_FILES=0

# =============================================================================
# SECTION 5 — MIGRATIONS SQL FLYWAY
# =============================================================================
log_sec "5/8 Migrations SQL Flyway"
mk "$RES/db/migration"
for migration in \
  "V1__create_utilisateurs:Tables utilisateurs index triggers" \
  "V2__create_cours_modules:Tables cours modules lecons QCM categories" \
  "V3__create_progression:Tables progression reponses badges" \
  "V4__create_paiement:Tables paiements tranches factures moratoires" \
  "V5__create_session:Tables sessions creneaux devoirs rendus" \
  "V6__create_certificat:Tables certificats notifications" \
  "V7__create_communaute:Tables messages communaute signalements" \
  "V8__create_securite:Tables refresh reset tokens audit logs RLS" \
  "V9__indexes_performance:Index composites critiques performances" \
  "V10__constraints_check:Contraintes CHECK regles metier BDD"
do
  name="${migration%%:*}"
  desc="${migration##*:}"
  stub_sql "$RES/db/migration/${name}.sql" "$desc"
  count
done
log_ok "Migrations SQL : 10 fichiers Flyway"
SQL_COUNT=$TOTAL_FILES; TOTAL_FILES=0

# =============================================================================
# SECTION 6 — TESTS
# =============================================================================
log_sec "6/8 Tests"
T="com.mbem.mbemlevel"
mk "$TEST_PKG/domain"
mk "$TEST_PKG/application/usecase"
mk "$TEST_PKG/infrastructure/persistence"
mk "$TEST_PKG/api/controller"
mk "$TEST_PKG/api/security"
mk "$TEST_PKG/architecture"
mk "$TEST_RES"

# Tests domaine (pur Java — aucun Spring context)
for t in CoursService ProgressionService PaiementService CertificatService; do
  stub_java "$TEST_PKG/domain/${t}Test.java" "$T.domain" "class" "${t}Test" "@Test unitaire pur — zéro Spring"; count
done

# Tests use cases (Mockito)
for t in InscrireApprenant ConnecterUtilisateur EnregistrerPaiement ValiderQCM GenererCertificat; do
  stub_java "$TEST_PKG/application/usecase/${t}UseCaseTest.java" "$T.application.usecase" "class" "${t}UseCaseTest" "@Test Mockito — ports mockés"; count
done

# Tests intégration (Testcontainers)
for t in Utilisateur Cours Progression; do
  stub_java "$TEST_PKG/infrastructure/persistence/${t}RepositoryIT.java" "$T.infrastructure.persistence" "class" "${t}RepositoryIT" "@Testcontainers — PostgreSQL réel"; count
done

# Tests API (SpringBootTest + MockMvc)
stub_java "$TEST_PKG/api/controller/AuthControllerIT.java"    "$T.api.controller" "class" "AuthControllerIT"   "@SpringBootTest — flux auth complet"; count
stub_java "$TEST_PKG/api/controller/CoursControllerIT.java"   "$T.api.controller" "class" "CoursControllerIT"  "@SpringBootTest — RBAC catalogue"; count
stub_java "$TEST_PKG/api/controller/PaiementControllerIT.java" "$T.api.controller" "class" "PaiementControllerIT" "@SpringBootTest — paiement moratoire"; count

# Tests sécurité
stub_java "$TEST_PKG/api/security/SecurityIT.java"     "$T.api.security" "class" "SecurityIT"    "@SpringBootTest — RBAC token expiré SQL injection"; count
stub_java "$TEST_PKG/api/security/RateLimitIT.java"    "$T.api.security" "class" "RateLimitIT"   "@SpringBootTest — 429 après dépassement"; count
stub_java "$TEST_PKG/api/security/JwtProviderTest.java" "$T.api.security" "class" "JwtProviderTest" "@Test — génération validation rotation tokens"; count

# Test ArchUnit
stub_java "$TEST_PKG/architecture/ArchitectureTest.java" "$T.architecture" "class" "ArchitectureTest" "@ArchTest — respect couches hexagonales"; count

# Ressources test
stub_file "$TEST_RES/application-test.yaml" "Surcharge test — Testcontainers PostgreSQL"
count

log_ok "Tests : $TOTAL_FILES fichiers"
TEST_COUNT=$TOTAL_FILES; TOTAL_FILES=0

# =============================================================================
# SECTION 7 — RESSOURCES STATIQUES
# =============================================================================
log_sec "7/8 Ressources"
mk "$RES/static"
mk "$RES/templates/email"
mk "$RES/templates/pdf"

stub_file "$RES/messages.properties"    "Messages d'erreur externalisés — internationalisation" ""
stub_file "$RES/messages_fr.properties" "Messages d'erreur en français" ""
count; count

log_ok "Ressources : dossiers et stubs"

# =============================================================================
# SECTION 8 — DEVOPS (Docker, Nginx, CI/CD, Monitoring, Docs)
# =============================================================================
log_sec "8/8 DevOps & Infrastructure"
mk "$ROOT/.github/workflows"
mk "$ROOT/nginx"
mk "$ROOT/monitoring/grafana/dashboards"
mk "$ROOT/monitoring/logstash"
mk "$ROOT/docs"

stub_file "$ROOT/docker-compose.yml"         "Docker Compose dev — PostgreSQL Redis MinIO MailHog"    ""
stub_file "$ROOT/docker-compose.test.yml"    "Docker Compose test — isolation CI"                     ""
stub_file "$ROOT/.env.example"               "Variables d'environnement — JAMAIS commiter .env réel"   ""
stub_file "$ROOT/Dockerfile"                 "Multi-stage build — JRE 21 alpine securisé"              ""
stub_file "$ROOT/Makefile"                   "Commandes dev : make run test migrate build deploy"       ""
stub_file "$ROOT/nginx/nginx.conf"           "Nginx reverse proxy HTTPS"                               ""
stub_file "$ROOT/nginx/ssl.conf"             "Nginx SSL TLS 1.3 HSTS ciphers"                         ""
stub_file "$ROOT/.github/workflows/ci.yml"  "CI GitHub Actions — build test sécurité"                 ""
stub_file "$ROOT/.github/workflows/cd.yml"  "CD GitHub Actions — deploy VPS auto après merge main"    ""
stub_file "$ROOT/.github/workflows/security.yml" "OWASP SAST Dependabot"                             ""
stub_file "$ROOT/monitoring/prometheus.yml"       "Prometheus scrape Actuator"                        ""
stub_file "$ROOT/monitoring/grafana/dashboards/mbemnova.json"  "Dashboard Grafana métriques API"       ""
stub_file "$ROOT/monitoring/logstash/pipeline.conf" "Logstash pipeline JSON logs → Elasticsearch"    ""
stub_file "$ROOT/docs/architecture.md"       "Architecture hexagonale et décisions techniques"         ""
stub_file "$ROOT/docs/api.md"                "API endpoints authentification exemples"                  ""
stub_file "$ROOT/docs/securite.md"           "Sécurité pratiques incidents procedures"                 ""
stub_file "$ROOT/docs/deploiement.md"        "Déploiement VPS nginx docker CI/CD"                     ""
stub_file "$ROOT/CHANGELOG.md"               "Historique des changements par version"                   ""
for f in "$ROOT/docker-compose.yml" "$ROOT/docker-compose.test.yml" "$ROOT/.env.example" "$ROOT/Dockerfile" "$ROOT/Makefile" "$ROOT/nginx/nginx.conf" "$ROOT/nginx/ssl.conf" "$ROOT/.github/workflows/ci.yml" "$ROOT/.github/workflows/cd.yml" "$ROOT/.github/workflows/security.yml" "$ROOT/monitoring/prometheus.yml" "$ROOT/monitoring/grafana/dashboards/mbemnova.json" "$ROOT/monitoring/logstash/pipeline.conf" "$ROOT/docs/architecture.md" "$ROOT/docs/api.md" "$ROOT/docs/securite.md" "$ROOT/docs/deploiement.md" "$ROOT/CHANGELOG.md"; do
  count
done

log_ok "DevOps : $TOTAL_FILES fichiers"

# =============================================================================
# RÉSUMÉ FINAL
# =============================================================================
GRAND_TOTAL=$((D_COUNT + A_COUNT + I_COUNT + API_COUNT + SQL_COUNT + TEST_COUNT + 2 + TOTAL_FILES))

echo ""
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo -e "${C_BOLD}${C_GREEN}  Script 02/15 terminé avec succès              ${C_NC}"
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo ""
echo -e "  ${C_GREEN}✓${C_NC}  Domain         : ${D_COUNT}  fichiers"
echo -e "  ${C_GREEN}✓${C_NC}  Application    : ${A_COUNT}  fichiers"
echo -e "  ${C_GREEN}✓${C_NC}  Infrastructure : ${I_COUNT}  fichiers"
echo -e "  ${C_GREEN}✓${C_NC}  API            : ${API_COUNT}  fichiers"
echo -e "  ${C_GREEN}✓${C_NC}  SQL Flyway     : ${SQL_COUNT}  fichiers"
echo -e "  ${C_GREEN}✓${C_NC}  Tests          : ${TEST_COUNT}  fichiers"
echo -e "  ${C_GREEN}✓${C_NC}  DevOps & docs  : ${TOTAL_FILES}  fichiers"
echo ""
echo -e "  ${C_BOLD}Total arborescence : ~$GRAND_TOTAL fichiers créés${C_NC}"
echo ""
echo -e "  ${C_YELLOW}→ Prochain script : ./s03_domain.sh${C_NC}"
echo ""
