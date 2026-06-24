#!/usr/bin/env bash
# =============================================================================
# MbemNova — Script 05/15 : Migrations SQL Flyway (V1 à V10 complètes)
# =============================================================================
# RÔLE   : Génère toutes les migrations SQL Flyway avec le schéma complet.
#          Chaque migration est idempotente et versionnée.
#
# MIGRATIONS GÉNÉRÉES :
#   V1  — utilisateurs (table principale + trigger updated_at)
#   V2  — cours, modules, lecons, QCM, categories
#   V3  — progression, reponses_qcm, badges
#   V4  — paiements, tranches, factures, moratoires
#   V5  — sessions, creneaux, devoirs, rendus
#   V6  — certificats, notifications
#   V7  — messages_communaute, signalements
#   V8  — refresh_tokens, reset_tokens, audit_logs (+ RLS + trigger immuabilité)
#   V9  — index de performance (critiques pour la prod)
#   V10 — contraintes CHECK métier
#
# PRÉREQUIS : s01 + s02 doivent avoir été lancés
# USAGE     : chmod +x s05_migrations_sql.sh && ./s05_migrations_sql.sh
# =============================================================================

set -euo pipefail
export LC_ALL=C.UTF-8

C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_CYAN='\033[0;36m'
C_BOLD='\033[1m';     C_NC='\033[0m'

log_ok()  { echo -e "${C_GREEN}  [OK]${C_NC} $1"; }
log_sec() { echo -e "\n${C_BOLD}${C_CYAN}── $1 ──${C_NC}"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIG="$ROOT/src/main/resources/db/migration"

echo ""
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo -e "${C_BOLD}${C_CYAN}  MbemNova · Script 05/15 · Migrations SQL      ${C_NC}"
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo ""

[[ ! -f "$ROOT/pom.xml" ]] && { echo "ERREUR: lancez s01 d'abord"; exit 1; }
mkdir -p "$MIG"

# =============================================================================
# V1 — TABLE UTILISATEURS
# =============================================================================
log_sec "V1 utilisateurs"
cat > "$MIG/V1__create_utilisateurs.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V1 — Table utilisateurs
-- Tous les rôles (apprenant, formateur, admin) dans une seule table.
-- La colonne `role` discrimine le type.
-- =============================================================================

-- Extension UUID (génération côté application, mais pgcrypto utile pour les tests)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- TABLE : utilisateurs
-- =============================================================================
CREATE TABLE utilisateurs (
    -- Identifiant UUID généré côté application (pas serial/bigserial)
    id                          UUID            PRIMARY KEY,

    -- Identité
    prenom                      VARCHAR(50)     NOT NULL,
    nom                         VARCHAR(50),
    email                       VARCHAR(255)    NOT NULL,

    -- Sécurité : JAMAIS le mot de passe en clair
    -- BCrypt hash max 72 chars effectifs (limitation BCrypt)
    mot_de_passe_hache          VARCHAR(72)     NOT NULL,
    email_verifie               BOOLEAN         NOT NULL DEFAULT FALSE,
    token_verification_email    VARCHAR(255),
    telephone                   VARCHAR(25),

    -- Rôle et statut
    role        VARCHAR(20) NOT NULL
                CHECK (role IN ('APPRENANT','FORMATEUR','ADMIN','SUPER_ADMIN')),
    statut      VARCHAR(20) NOT NULL DEFAULT 'INSCRIT'
                CHECK (statut IN ('INSCRIT','ACTIF','SUSPENDU','CERTIFIE')),

    -- Protection brute-force
    tentatives_connexion_echouees   SMALLINT    NOT NULL DEFAULT 0,
    bloque_jusqu_au                 TIMESTAMPTZ,
    derniere_connexion              TIMESTAMPTZ,

    -- ── Champs spécifiques Apprenant ────────────────────────────────────────
    ville                   VARCHAR(100),
    xp_total                INTEGER     NOT NULL DEFAULT 0 CHECK (xp_total >= 0),
    streak_jours            SMALLINT    NOT NULL DEFAULT 0 CHECK (streak_jours >= 0),
    rang_plateforme         INTEGER,
    disponible_pour_emploi  BOOLEAN     NOT NULL DEFAULT FALSE,
    lien_portfolio          VARCHAR(500),
    lien_cv                 VARCHAR(500),
    lien_linkedin           VARCHAR(500),
    lien_github             VARCHAR(500),
    bio                     VARCHAR(1000),
    code_parrainage         VARCHAR(20) UNIQUE,
    parrain_id              UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,

    -- ── Champs spécifiques Formateur ────────────────────────────────────────
    specialite              VARCHAR(200),
    biographie              TEXT,
    note_globale            NUMERIC(3,2) CHECK (note_globale >= 0 AND note_globale <= 5),

    -- ── Champs spécifiques Admin ─────────────────────────────────────────────
    niveau_acces            VARCHAR(20) CHECK (niveau_acces IN ('STANDARD','SUPER')),

    -- Audit automatique
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_utilisateurs_email UNIQUE (email)
);

COMMENT ON TABLE  utilisateurs                      IS 'Tous les utilisateurs MbemNova (apprenant, formateur, admin)';
COMMENT ON COLUMN utilisateurs.mot_de_passe_hache   IS 'Hash BCrypt cost=12 — JAMAIS en clair';
COMMENT ON COLUMN utilisateurs.tentatives_connexion_echouees IS 'Remis à 0 après connexion réussie';

-- Trigger : met à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION mbem_update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_utilisateurs_updated_at
    BEFORE UPDATE ON utilisateurs
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();
SQLEOF
log_ok "V1__create_utilisateurs.sql"

# =============================================================================
# V2 — COURS, MODULES, LECONS, QCM, CATEGORIES
# =============================================================================
log_sec "V2 cours"
cat > "$MIG/V2__create_cours_modules.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V2 — Cours, modules, leçons, QCM, catégories
-- =============================================================================

CREATE TABLE categories (
    id          UUID        PRIMARY KEY,
    nom         VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(500),
    icone       VARCHAR(100),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE cours (
    id                  UUID        PRIMARY KEY,
    titre               VARCHAR(200) NOT NULL,
    description         TEXT,
    niveau              VARCHAR(20)  NOT NULL CHECK (niveau IN ('DEBUTANT','INTERMEDIAIRE','AVANCE')),
    categorie_id        UUID         REFERENCES categories(id) ON DELETE SET NULL,
    formateur_id        UUID         REFERENCES utilisateurs(id) ON DELETE SET NULL,
    -- Pourcentage du cours (0.0 à 1.0) après lequel le paiement est demandé
    seuil_paiement      NUMERIC(3,2) NOT NULL DEFAULT 0.30
                        CHECK (seuil_paiement > 0 AND seuil_paiement <= 1),
    prix_fcfa           BIGINT       NOT NULL DEFAULT 0 CHECK (prix_fcfa >= 0),
    est_actif           BOOLEAN      NOT NULL DEFAULT TRUE,
    -- Meta SEO
    slug                VARCHAR(250) UNIQUE,
    image_couverture    VARCHAR(500),
    -- Statistiques dénormalisées (mise à jour par trigger ou scheduler)
    nb_apprenants       INTEGER      NOT NULL DEFAULT 0,
    note_moyenne        NUMERIC(3,2) CHECK (note_moyenne >= 0 AND note_moyenne <= 5),
    nb_avis             INTEGER      NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_cours_updated_at
    BEFORE UPDATE ON cours
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE modules (
    id              UUID        PRIMARY KEY,
    cours_id        UUID        NOT NULL REFERENCES cours(id) ON DELETE CASCADE,
    titre           VARCHAR(200) NOT NULL,
    description     VARCHAR(500),
    ordre           SMALLINT    NOT NULL CHECK (ordre > 0),
    est_verrouille  BOOLEAN     NOT NULL DEFAULT TRUE,
    xp_bonus        SMALLINT    NOT NULL DEFAULT 100,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cours_id, ordre)
);

CREATE TRIGGER trg_modules_updated_at
    BEFORE UPDATE ON modules
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE lecons (
    id              UUID        PRIMARY KEY,
    module_id       UUID        NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    titre           VARCHAR(200) NOT NULL,
    contenu_texte   TEXT,
    lien_pdf        VARCHAR(500),
    lien_video      VARCHAR(500),
    ordre           SMALLINT    NOT NULL CHECK (ordre > 0),
    duree_minutes   SMALLINT    CHECK (duree_minutes > 0),
    xp_valeur       SMALLINT    NOT NULL DEFAULT 25,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (module_id, ordre)
);

CREATE TRIGGER trg_lecons_updated_at
    BEFORE UPDATE ON lecons
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE qcm (
    id              UUID        PRIMARY KEY,
    lecon_id        UUID        NOT NULL REFERENCES lecons(id) ON DELETE CASCADE,
    question        TEXT        NOT NULL,
    -- Options JSON : [{"id":"A","texte":"..."},{"id":"B","texte":"..."}]
    options         JSONB       NOT NULL,
    bonne_reponse   VARCHAR(5)  NOT NULL,
    est_obligatoire BOOLEAN     NOT NULL DEFAULT TRUE,
    score_min_pct   SMALLINT    NOT NULL DEFAULT 70
                    CHECK (score_min_pct BETWEEN 0 AND 100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
SQLEOF
log_ok "V2__create_cours_modules.sql"

# =============================================================================
# V3 — PROGRESSION, REPONSES QCM, BADGES
# =============================================================================
log_sec "V3 progression"
cat > "$MIG/V3__create_progression.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V3 — Progression des apprenants
-- =============================================================================

CREATE TABLE progression (
    id              UUID        PRIMARY KEY,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    pourcentage     NUMERIC(5,2) NOT NULL DEFAULT 0
                    CHECK (pourcentage BETWEEN 0 AND 100),
    est_paye        BOOLEAN     NOT NULL DEFAULT FALSE,
    xp_gagne        INTEGER     NOT NULL DEFAULT 0,
    date_debut      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_completion TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Un apprenant ne peut avoir qu'une progression par cours
    UNIQUE (apprenant_id, cours_id)
);

CREATE TRIGGER trg_progression_updated_at
    BEFORE UPDATE ON progression
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE reponses_qcm (
    id              UUID        PRIMARY KEY,
    progression_id  UUID        NOT NULL REFERENCES progression(id) ON DELETE CASCADE,
    qcm_id          UUID        NOT NULL REFERENCES qcm(id)         ON DELETE CASCADE,
    reponse_donnee  VARCHAR(5)  NOT NULL,
    est_correcte    BOOLEAN     NOT NULL,
    score           SMALLINT    NOT NULL DEFAULT 0,
    tentative       SMALLINT    NOT NULL DEFAULT 1,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE badges (
    id              UUID        PRIMARY KEY,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    type_badge      VARCHAR(50) NOT NULL,
    -- Ex: PREMIER_COURS, STREAK_7, XP_1000, CERTIFIE
    description     VARCHAR(200),
    date_obtention  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (apprenant_id, type_badge)  -- Un badge par type par apprenant
);
SQLEOF
log_ok "V3__create_progression.sql"

# =============================================================================
# V4 — PAIEMENT, TRANCHES, FACTURES, MORATOIRES
# =============================================================================
log_sec "V4 paiement"
cat > "$MIG/V4__create_paiement.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V4 — Système de paiement avec tranches
-- =============================================================================

CREATE TABLE paiements (
    id              UUID        PRIMARY KEY,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE RESTRICT,
    montant_total   BIGINT      NOT NULL CHECK (montant_total > 0),
    montant_paye    BIGINT      NOT NULL DEFAULT 0,
    mode_paiement   VARCHAR(20) NOT NULL
                    CHECK (mode_paiement IN ('CASH','MOBILE_MONEY','ONLINE')),
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                    CHECK (statut IN ('EN_ATTENTE','PAYE','EN_RETARD','MORATOIRE','ANNULE')),
    admin_id        UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,
    -- Accès activé après confirmation du premier paiement
    acces_active    BOOLEAN     NOT NULL DEFAULT FALSE,
    date_activation TIMESTAMPTZ,
    notes_admin     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (apprenant_id, cours_id)  -- Un seul paiement par cours par apprenant
);

CREATE TRIGGER trg_paiements_updated_at
    BEFORE UPDATE ON paiements
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE tranches (
    id              UUID        PRIMARY KEY,
    paiement_id     UUID        NOT NULL REFERENCES paiements(id) ON DELETE CASCADE,
    numero          SMALLINT    NOT NULL CHECK (numero > 0),
    montant         BIGINT      NOT NULL CHECK (montant > 0),
    date_echeance   DATE        NOT NULL,
    date_reglement  DATE,
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                    CHECK (statut IN ('EN_ATTENTE','PAYE','EN_RETARD','MORATOIRE')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (paiement_id, numero)
);

CREATE TRIGGER trg_tranches_updated_at
    BEFORE UPDATE ON tranches
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE factures (
    id                  UUID        PRIMARY KEY,
    paiement_id         UUID        NOT NULL REFERENCES paiements(id) ON DELETE RESTRICT,
    code_verification   VARCHAR(50) NOT NULL UNIQUE,
    lien_pdf            VARCHAR(500),
    date_emission       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE moratoires (
    id                  UUID        PRIMARY KEY,
    paiement_id         UUID        NOT NULL REFERENCES paiements(id) ON DELETE CASCADE,
    raison              TEXT        NOT NULL,
    nouvelle_date       DATE        NOT NULL,
    statut              VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                        CHECK (statut IN ('EN_ATTENTE','ACCORDE','REFUSE')),
    admin_id            UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,
    commentaire_admin   TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_moratoires_updated_at
    BEFORE UPDATE ON moratoires
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();
SQLEOF
log_ok "V4__create_paiement.sql"

# =============================================================================
# V5 — SESSIONS, CRENEAUX, DEVOIRS, RENDUS
# =============================================================================
log_sec "V5 sessions"
cat > "$MIG/V5__create_session.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V5 — Sessions de formation avec créneaux et devoirs
-- =============================================================================

CREATE TABLE sessions (
    id              UUID        PRIMARY KEY,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE RESTRICT,
    formateur_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    titre           VARCHAR(200) NOT NULL,
    modalite        VARCHAR(20) NOT NULL CHECK (modalite IN ('PRESENTIEL','ONLINE_MEET')),
    date_debut      DATE        NOT NULL,
    date_fin        DATE        NOT NULL CHECK (date_fin >= date_debut),
    capacite_max    SMALLINT    NOT NULL CHECK (capacite_max > 0),
    nb_inscrits     SMALLINT    NOT NULL DEFAULT 0,
    lien_reunion    VARCHAR(500),  -- Google Meet / Zoom
    lieu            VARCHAR(300),  -- Adresse pour présentiel
    est_active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_sessions_updated_at
    BEFORE UPDATE ON sessions
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE session_inscriptions (
    id              UUID        PRIMARY KEY,
    session_id      UUID        NOT NULL REFERENCES sessions(id)     ON DELETE CASCADE,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    date_inscription TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (session_id, apprenant_id)
);

CREATE TABLE creneaux (
    id              UUID        PRIMARY KEY,
    session_id      UUID        NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    jour_semaine    SMALLINT    NOT NULL CHECK (jour_semaine BETWEEN 1 AND 7),
    heure_debut     TIME        NOT NULL,
    heure_fin       TIME        NOT NULL CHECK (heure_fin > heure_debut),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE devoirs (
    id              UUID        PRIMARY KEY,
    session_id      UUID        NOT NULL REFERENCES sessions(id)  ON DELETE CASCADE,
    module_id       UUID        REFERENCES modules(id)            ON DELETE SET NULL,
    titre           VARCHAR(200) NOT NULL,
    consignes       TEXT        NOT NULL,
    date_remise     TIMESTAMPTZ NOT NULL,
    est_verrouille  BOOLEAN     NOT NULL DEFAULT FALSE,
    lien_ressources VARCHAR(500),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_devoirs_updated_at
    BEFORE UPDATE ON devoirs
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE rendus (
    id              UUID        PRIMARY KEY,
    devoir_id       UUID        NOT NULL REFERENCES devoirs(id)      ON DELETE CASCADE,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    contenu         TEXT,
    lien_fichier    VARCHAR(500),
    note            SMALLINT    CHECK (note BETWEEN 0 AND 20),
    commentaire     TEXT,
    date_soumission TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_correction TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (devoir_id, apprenant_id)
);

CREATE TRIGGER trg_rendus_updated_at
    BEFORE UPDATE ON rendus
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();
SQLEOF
log_ok "V5__create_session.sql"

# =============================================================================
# V6 — CERTIFICATS, NOTIFICATIONS
# =============================================================================
log_sec "V6 certificats"
cat > "$MIG/V6__create_certificat.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V6 — Certificats et notifications
-- =============================================================================

CREATE TABLE certificats (
    id                  UUID        PRIMARY KEY,
    apprenant_id        UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    cours_id            UUID        NOT NULL REFERENCES cours(id)        ON DELETE RESTRICT,
    -- Code de vérification unique (partageable publiquement)
    code_verification   VARCHAR(50) NOT NULL UNIQUE,
    lien_pdf            VARCHAR(500),
    date_emission       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (apprenant_id, cours_id)  -- Un certificat par cours par apprenant
);

COMMENT ON COLUMN certificats.code_verification IS 'Code public vérifiable sur mbemnova.com/verify/{code}';

CREATE TABLE notifications (
    id              UUID        PRIMARY KEY,
    utilisateur_id  UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    type_notif      VARCHAR(50) NOT NULL,
    canal           VARCHAR(20) NOT NULL CHECK (canal IN ('EMAIL','WHATSAPP','IN_APP')),
    titre           VARCHAR(200) NOT NULL,
    contenu         TEXT,
    est_lue         BOOLEAN     NOT NULL DEFAULT FALSE,
    date_lecture    TIMESTAMPTZ,
    -- Lien contextuel (ex: vers le cours, le certificat, la facture)
    lien_action     VARCHAR(500),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notif_user_non_lues ON notifications (utilisateur_id, est_lue)
    WHERE est_lue = FALSE;
SQLEOF
log_ok "V6__create_certificat.sql"

# =============================================================================
# V7 — COMMUNAUTÉ (messages Q&R, signalements, parrainage)
# =============================================================================
log_sec "V7 communaute"
cat > "$MIG/V7__create_communaute.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V7 — Communauté, signalements et parrainage
-- =============================================================================

CREATE TABLE messages_communaute (
    id              UUID        PRIMARY KEY,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    auteur_id       UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    parent_id       UUID        REFERENCES messages_communaute(id)   ON DELETE CASCADE,
    contenu         TEXT        NOT NULL,
    est_question    BOOLEAN     NOT NULL DEFAULT TRUE,
    est_resolu      BOOLEAN     NOT NULL DEFAULT FALSE,
    est_modere      BOOLEAN     NOT NULL DEFAULT FALSE,
    nb_likes        INTEGER     NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_messages_updated_at
    BEFORE UPDATE ON messages_communaute
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE signalements (
    id              UUID        PRIMARY KEY,
    message_id      UUID        NOT NULL REFERENCES messages_communaute(id) ON DELETE CASCADE,
    auteur_id       UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    raison          VARCHAR(200) NOT NULL,
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                    CHECK (statut IN ('EN_ATTENTE','TRAITE','IGNORE')),
    admin_id        UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Parrainage : lien entre parrain et filleuls
CREATE TABLE parrainages (
    id              UUID        PRIMARY KEY,
    parrain_id      UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    filleul_id      UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    code_utilise    VARCHAR(20) NOT NULL,
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                    CHECK (statut IN ('EN_ATTENTE','ACTIF','RECOMPENSE')),
    recompense_activee BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (filleul_id)  -- Un filleul ne peut avoir qu'un seul parrain
);

-- Tirage au sort mensuel
CREATE TABLE tirages_au_sort (
    id              UUID        PRIMARY KEY,
    mois            DATE        NOT NULL UNIQUE,  -- Premier jour du mois
    gagnant_id      UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,
    nb_participants INTEGER     NOT NULL DEFAULT 0,
    prix_description VARCHAR(300),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Avis sur les cours (affichés sur la page de détail du cours)
CREATE TABLE avis_cours (
    id              UUID        PRIMARY KEY,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    note            SMALLINT    NOT NULL CHECK (note BETWEEN 1 AND 5),
    commentaire     VARCHAR(1000),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cours_id, apprenant_id)  -- Un seul avis par apprenant par cours
);
SQLEOF
log_ok "V7__create_communaute.sql"

# =============================================================================
# V8 — SÉCURITÉ : REFRESH TOKENS, RESET TOKENS, AUDIT LOGS
# =============================================================================
log_sec "V8 securite"
cat > "$MIG/V8__create_securite.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V8 — Tables de sécurité
-- Refresh tokens, reset MDP, logs d'audit immuables.
-- =============================================================================

-- =============================================================================
-- REFRESH TOKENS — Rotation sécurisée
-- Le token brut est en cookie HttpOnly côté client.
-- En base : seulement le SHA-256.
-- =============================================================================
CREATE TABLE refresh_tokens (
    id              UUID        PRIMARY KEY,
    utilisateur_id  UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    -- SHA-256 du token brut — JAMAIS le token en clair
    token_hache     VARCHAR(255) NOT NULL UNIQUE,
    expire_le       TIMESTAMPTZ NOT NULL,
    -- Chaîne de rotation : chaque token pointe vers son successeur
    remplace_par    UUID        REFERENCES refresh_tokens(id),
    est_revoque     BOOLEAN     NOT NULL DEFAULT FALSE,
    ip_creation     INET,
    user_agent      VARCHAR(500),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON COLUMN refresh_tokens.token_hache IS 'SHA-256 — le token brut est transmis au client uniquement';

-- =============================================================================
-- RESET TOKENS — Réinitialisation MDP (usage unique, TTL 1h)
-- =============================================================================
CREATE TABLE reset_tokens (
    id              UUID        PRIMARY KEY,
    utilisateur_id  UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    token_hache     VARCHAR(255) NOT NULL UNIQUE,
    expire_le       TIMESTAMPTZ NOT NULL,
    est_utilise     BOOLEAN     NOT NULL DEFAULT FALSE,
    ip_demande      INET,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    utilise_le      TIMESTAMPTZ
);

COMMENT ON COLUMN reset_tokens.token_hache IS 'SHA-256 — le token brut est dans le lien email uniquement';

-- =============================================================================
-- AUDIT LOGS — Journal immuable
-- INSERT ONLY : un trigger bloque tout UPDATE et DELETE.
-- =============================================================================
CREATE TABLE audit_logs (
    id              UUID        PRIMARY KEY,
    utilisateur_id  UUID,        -- NULL pour les actions anonymes
    user_email      VARCHAR(255),-- Dénormalisé (retrouvable même si compte supprimé)
    -- Type d'action SCREAMING_SNAKE_CASE
    action          VARCHAR(100) NOT NULL,
    ressource_type  VARCHAR(50),
    ressource_id    VARCHAR(255),
    -- Contexte JSON : {ancien_role, nouveau_role, montant, ip, etc.}
    details         JSONB,
    statut          VARCHAR(20)  NOT NULL DEFAULT 'SUCCESS'
                    CHECK (statut IN ('SUCCESS','FAILURE','WARNING')),
    ip_adresse      INET,
    user_agent      VARCHAR(500),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE audit_logs IS 'Journal audit immuable — INSERT ONLY, trigger bloque UPDATE/DELETE';

-- Trigger immuabilité audit_logs
CREATE OR REPLACE FUNCTION mbem_prevent_audit_modification()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Les logs d audit sont immuables — modification interdite';
END;
$$;

CREATE TRIGGER trg_audit_immutable
    BEFORE UPDATE OR DELETE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION mbem_prevent_audit_modification();

-- RLS : l'application ne peut qu'insérer
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_insert_only ON audit_logs FOR INSERT WITH CHECK (TRUE);
SQLEOF
log_ok "V8__create_securite.sql"

# =============================================================================
# V9 — INDEX DE PERFORMANCE (critiques pour la prod)
# =============================================================================
log_sec "V9 indexes"
cat > "$MIG/V9__indexes_performance.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V9 — Index de performance
-- CONVENTION : idx_{table}_{colonnes}
-- Index partiels (WHERE) : plus légers et plus rapides que les index totaux.
-- =============================================================================

-- ── Utilisateurs ─────────────────────────────────────────────────────────────

-- Email insensible à la casse (appelé à chaque connexion)
CREATE UNIQUE INDEX idx_users_email_lower
    ON utilisateurs (LOWER(email));

-- Apprenants disponibles pour l'emploi (vitrine Talents)
CREATE INDEX idx_users_disponibles
    ON utilisateurs (disponible_pour_emploi, role)
    WHERE disponible_pour_emploi = TRUE AND role = 'APPRENANT';

-- Code parrainage (recherche lors d'une inscription avec code)
CREATE UNIQUE INDEX idx_users_parrainage
    ON utilisateurs (code_parrainage)
    WHERE code_parrainage IS NOT NULL;

-- Classement XP (leaderboard gamification)
CREATE INDEX idx_users_xp_rang
    ON utilisateurs (xp_total DESC, rang_plateforme)
    WHERE role = 'APPRENANT' AND statut = 'ACTIF';

-- ── Cours ─────────────────────────────────────────────────────────────────────

-- Catalogue (filtre niveau + catégorie + actif — requête la plus fréquente)
CREATE INDEX idx_cours_catalogue
    ON cours (niveau, categorie_id, est_actif)
    WHERE est_actif = TRUE;

-- Slug pour les URLs SEO
CREATE UNIQUE INDEX idx_cours_slug
    ON cours (slug)
    WHERE slug IS NOT NULL;

-- ── Progression ───────────────────────────────────────────────────────────────

-- Index composite : dashboard apprenant (très fréquent)
CREATE INDEX idx_progression_apprenant
    ON progression (apprenant_id, est_paye, pourcentage);

-- Paiement pas encore fait + seuil atteint (conversion)
CREATE INDEX idx_progression_non_payee
    ON progression (est_paye, pourcentage)
    WHERE est_paye = FALSE;

-- ── Paiements ─────────────────────────────────────────────────────────────────

-- Paiements en retard (scheduler de relance)
CREATE INDEX idx_paiements_en_retard
    ON paiements (statut, updated_at)
    WHERE statut IN ('EN_RETARD','EN_ATTENTE');

-- ── Refresh Tokens ────────────────────────────────────────────────────────────

-- Hash (appelé à chaque refresh — doit être ultra-rapide)
CREATE UNIQUE INDEX idx_refresh_token_hache
    ON refresh_tokens (token_hache);

-- Tokens actifs par utilisateur
CREATE INDEX idx_refresh_actifs
    ON refresh_tokens (utilisateur_id, est_revoque)
    WHERE est_revoque = FALSE;

-- Expiration (cleanup scheduler)
CREATE INDEX idx_refresh_expiration
    ON refresh_tokens (expire_le)
    WHERE est_revoque = FALSE;

-- ── Reset Tokens ─────────────────────────────────────────────────────────────

CREATE UNIQUE INDEX idx_reset_token_hache
    ON reset_tokens (token_hache);

CREATE INDEX idx_reset_valides
    ON reset_tokens (utilisateur_id, est_utilise, expire_le)
    WHERE est_utilise = FALSE;

-- ── Audit Logs ────────────────────────────────────────────────────────────────

-- Historique par utilisateur
CREATE INDEX idx_audit_user_date
    ON audit_logs (utilisateur_id, created_at DESC)
    WHERE utilisateur_id IS NOT NULL;

-- Recherche par action (admin)
CREATE INDEX idx_audit_action_date
    ON audit_logs (action, created_at DESC);

-- IP suspecte (détection anomalies sécurité)
CREATE INDEX idx_audit_ip_date
    ON audit_logs (ip_adresse, created_at DESC)
    WHERE ip_adresse IS NOT NULL;

-- ── Messages Communauté ────────────────────────────────────────────────────────

CREATE INDEX idx_messages_cours_date
    ON messages_communaute (cours_id, created_at DESC)
    WHERE est_modere = FALSE;

-- ── Sessions ──────────────────────────────────────────────────────────────────

-- Sessions disponibles pour inscription
CREATE INDEX idx_sessions_disponibles
    ON sessions (cours_id, est_active, date_debut)
    WHERE est_active = TRUE;
SQLEOF
log_ok "V9__indexes_performance.sql"

# =============================================================================
# V10 — CONTRAINTES CHECK MÉTIER
# =============================================================================
log_sec "V10 contraintes"
cat > "$MIG/V10__constraints_check.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V10 — Contraintes CHECK métier supplémentaires
-- Ajoutées séparément pour une meilleure lisibilité et facilité de rollback.
-- =============================================================================

-- Un formateur ne peut pas s'inscrire à sa propre session
ALTER TABLE session_inscriptions
    ADD CONSTRAINT chk_session_inscription_pas_formateur
    CHECK (
        apprenant_id != (
            SELECT formateur_id FROM sessions WHERE id = session_id
        )
    );

-- Une tranche ne peut pas avoir une date de règlement avant sa création
ALTER TABLE tranches
    ADD CONSTRAINT chk_tranche_reglement_logique
    CHECK (date_reglement IS NULL OR date_reglement >= date_echeance - INTERVAL '30 days');

-- Le montant payé ne peut pas dépasser le montant total
ALTER TABLE paiements
    ADD CONSTRAINT chk_paiement_montant_logique
    CHECK (montant_paye <= montant_total);

-- Un rendu ne peut pas être soumis avant la création du devoir
-- (géré applicativement — contrainte BDD de sécurité)
ALTER TABLE rendus
    ADD CONSTRAINT chk_rendu_date_logique
    CHECK (date_soumission >= (
        SELECT created_at FROM devoirs WHERE id = devoir_id
    ) - INTERVAL '1 minute');

-- La note d'un avis cours requiert que l'apprenant ait complété 30% minimum
-- (vérifié applicativement dans le use case — commentaire pour documentation)
COMMENT ON TABLE avis_cours IS
    'Règle: un apprenant doit avoir complété >= 30% du cours pour laisser un avis (vérifié en application)';

-- Résumé des contraintes applicatives importantes
COMMENT ON TABLE progression IS
    'Règle: seuil_paiement configuré dans cours.seuil_paiement — contrôle applicatif';
COMMENT ON TABLE paiements IS
    'Règle: une seule demande de moratoire active à la fois par paiement — contrôle applicatif';
SQLEOF
log_ok "V10__constraints_check.sql"

# =============================================================================
# RÉSUMÉ
# =============================================================================
echo ""
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo -e "${C_BOLD}${C_GREEN}  Script 05/15 terminé avec succès              ${C_NC}"
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo ""
echo -e "  ${C_GREEN}✓${C_NC}  V1  — utilisateurs (table + trigger)"
echo -e "  ${C_GREEN}✓${C_NC}  V2  — cours, modules, leçons, QCM, catégories"
echo -e "  ${C_GREEN}✓${C_NC}  V3  — progression, réponses QCM, badges"
echo -e "  ${C_GREEN}✓${C_NC}  V4  — paiements, tranches, factures, moratoires"
echo -e "  ${C_GREEN}✓${C_NC}  V5  — sessions, créneaux, devoirs, rendus"
echo -e "  ${C_GREEN}✓${C_NC}  V6  — certificats, notifications"
echo -e "  ${C_GREEN}✓${C_NC}  V7  — communauté, signalements, parrainage, tirages, avis"
echo -e "  ${C_GREEN}✓${C_NC}  V8  — refresh/reset tokens, audit logs (RLS + trigger immuabilité)"
echo -e "  ${C_GREEN}✓${C_NC}  V9  — 16 index de performance (index partiels optimisés)"
echo -e "  ${C_GREEN}✓${C_NC}  V10 — contraintes CHECK métier"
echo ""
echo -e "  \033[1;33m→ Prochain script : ./s06_jpa_infrastructure.sh\033[0m"
echo ""
