#!/usr/bin/env bash
# =============================================================================
# MbemNova — s16_migrations_manquantes.sh
# Migrations SQL manquantes : V11 à V17
# Ne touche PAS aux migrations V1–V10 existantes
# =============================================================================
set -euo pipefail

ROOT="${1:-.}"
MIG="$ROOT/src/main/resources/db/migration"

C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_NC='\033[0m'
ok()  { echo -e "  ${C_GREEN}✓${C_NC}  $1"; }
sec() { echo -e "\n${C_BLUE}▶ $1${C_NC}"; }

mkdir -p "$MIG"

# =============================================================================
# V11 — AVIS SUR LES COURS (S4)
# =============================================================================
sec "V11 avis_cours"
cat > "$MIG/V11__create_avis_cours.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V11 — Avis apprenants sur les cours (S4)
-- Règle : un apprenant doit avoir complété >= 30% du cours payé pour laisser un avis
-- Un seul avis par apprenant par cours — pas de modification après publication
-- =============================================================================

CREATE TABLE avis_cours (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    note            SMALLINT    NOT NULL CHECK (note BETWEEN 1 AND 5),
    commentaire     TEXT,
    est_verifie     BOOLEAN     NOT NULL DEFAULT FALSE,
    -- Vérifié = apprenant a payé et complété >= 30%
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cours_id, apprenant_id)
);

COMMENT ON TABLE avis_cours IS
    'S4 — Avis vérifiés : apprenant doit avoir >= 30% progression payée. Un seul avis par cours.';

CREATE INDEX idx_avis_cours_cours_id   ON avis_cours(cours_id);
CREATE INDEX idx_avis_cours_apprenant  ON avis_cours(apprenant_id);
SQLEOF
ok "V11__create_avis_cours.sql"

# =============================================================================
# V12 — TABLE MORATOIRES COMPLÈTE (S17)
# La table existe partiellement dans V4 — cette migration ajoute les colonnes manquantes
# =============================================================================
sec "V12 moratoires complet"
cat > "$MIG/V12__complete_moratoires.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V12 — Complétion table moratoires (S17)
-- Ajoute statut et colonnes de traitement admin
-- =============================================================================

-- Vérifier si la table moratoires existe déjà (créée partiellement dans V4)
-- Si oui, on ajoute seulement les colonnes manquantes

DO $$
BEGIN
    -- Ajouter colonne statut si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='statut'
    ) THEN
        ALTER TABLE moratoires
            ADD COLUMN statut VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                CHECK (statut IN ('EN_ATTENTE','ACCORDE','REFUSE'));
    END IF;

    -- Ajouter admin_id si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='admin_id'
    ) THEN
        ALTER TABLE moratoires
            ADD COLUMN admin_id UUID REFERENCES utilisateurs(id) ON DELETE SET NULL;
    END IF;

    -- Ajouter justification_refus si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='justification_refus'
    ) THEN
        ALTER TABLE moratoires
            ADD COLUMN justification_refus TEXT;
    END IF;

    -- Ajouter date_decision si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='date_decision'
    ) THEN
        ALTER TABLE moratoires
            ADD COLUMN date_decision TIMESTAMPTZ;
    END IF;

    -- Ajouter updated_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='updated_at'
    ) THEN
        ALTER TABLE moratoires
            ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_moratoires_paiement ON moratoires(paiement_id);
CREATE INDEX IF NOT EXISTS idx_moratoires_statut   ON moratoires(statut) WHERE statut = 'EN_ATTENTE';

COMMENT ON TABLE moratoires IS
    'S17 — Demandes de délai de paiement. Statut EN_ATTENTE/ACCORDE/REFUSE géré par admin.';
SQLEOF
ok "V12__complete_moratoires.sql"

# =============================================================================
# V13 — CRÉNEAUX HORAIRES (S10)
# =============================================================================
sec "V13 creneaux"
cat > "$MIG/V13__create_creneaux.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V13 — Créneaux horaires des sessions (S10)
-- =============================================================================

CREATE TABLE creneaux (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID        NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    jour_semaine    VARCHAR(10) NOT NULL
                    CHECK (jour_semaine IN ('LUNDI','MARDI','MERCREDI','JEUDI','VENDREDI','SAMEDI','DIMANCHE')),
    heure_debut     TIME        NOT NULL,
    duree_minutes   SMALLINT    NOT NULL CHECK (duree_minutes > 0),
    capacite_max    SMALLINT    NOT NULL DEFAULT 30,
    places_restantes SMALLINT   NOT NULL DEFAULT 30,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Table de liaison apprenant ↔ créneau choisi
CREATE TABLE apprenant_creneaux (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    creneau_id      UUID        NOT NULL REFERENCES creneaux(id)     ON DELETE CASCADE,
    session_id      UUID        NOT NULL REFERENCES sessions(id)     ON DELETE CASCADE,
    date_choix      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (apprenant_id, creneau_id)
);

CREATE TRIGGER trg_creneaux_updated_at
    BEFORE UPDATE ON creneaux
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE INDEX idx_creneaux_session   ON creneaux(session_id);
CREATE INDEX idx_apprenant_creneaux ON apprenant_creneaux(apprenant_id);

COMMENT ON TABLE creneaux IS 'S10 — Créneaux horaires disponibles par session';
COMMENT ON TABLE apprenant_creneaux IS 'S10 — Choix de créneaux par les apprenants';
SQLEOF
ok "V13__create_creneaux.sql"

# =============================================================================
# V14 — BADGES COMPLETS (S6, S13)
# La table badges existe dans V3 — ajouter index manquants et table apprenant_badges
# =============================================================================
sec "V14 badges index"
cat > "$MIG/V14__create_badges_index.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V14 — Index et complétions pour badges (S6, S13)
-- La table badges est dans V3 — on ajoute seulement les index manquants
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_badges_apprenant ON badges(apprenant_id);
CREATE INDEX IF NOT EXISTS idx_badges_type      ON badges(type_badge);

-- Types de badges autorisés (documentation)
COMMENT ON TABLE badges IS
    'S6/S13 — Badges gamification. Types: PREMIER_COURS, MODULE_TERMINE, STREAK_7, STREAK_30, XP_500, XP_1000, CERTIFIE, ENTRAIDE';
SQLEOF
ok "V14__create_badges_index.sql"

# =============================================================================
# V15 — PARRAINAGE COMPLET (S15)
# =============================================================================
sec "V15 parrainage"
cat > "$MIG/V15__create_parrainage_complet.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V15 — Système de parrainage complet (S15)
-- =============================================================================

CREATE TABLE parrainages (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    parrain_id          UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    filleul_id          UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,
    code_parrainage     VARCHAR(20) NOT NULL UNIQUE,
    -- Lien unique mbemnova.com/ref/[code]
    statut              VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                        CHECK (statut IN ('EN_ATTENTE','ACTIF','RECOMPENSE_ACCORDEE')),
    -- ACTIF = filleul inscrit, RECOMPENSE = filleul a terminé son 1er module
    date_inscription    TIMESTAMPTZ,
    -- Date où le filleul a rejoint
    date_activation     TIMESTAMPTZ,
    -- Date où la récompense a été déclenchée (filleul termine 1er module)
    xp_parrain_credite  INTEGER     NOT NULL DEFAULT 0,
    xp_filleul_credite  INTEGER     NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_parrainages_updated_at
    BEFORE UPDATE ON parrainages
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE INDEX idx_parrainages_parrain ON parrainages(parrain_id);
CREATE INDEX idx_parrainages_code    ON parrainages(code_parrainage);
CREATE INDEX idx_parrainages_filleul ON parrainages(filleul_id) WHERE filleul_id IS NOT NULL;

-- Stocker le code de parrainage sur le compte utilisateur pour référence rapide
ALTER TABLE utilisateurs
    ADD COLUMN IF NOT EXISTS code_parrainage VARCHAR(20) UNIQUE;

COMMENT ON TABLE parrainages IS 'S15 — Suivi des parrainages et récompenses';
SQLEOF
ok "V15__create_parrainage_complet.sql"

# =============================================================================
# V16 — TIRAGE AU SORT — PERSISTANCE DES RÉSULTATS (S24)
# =============================================================================
sec "V16 tirage_resultats"
cat > "$MIG/V16__create_tirage_resultats.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V16 — Persistance des tirages au sort mensuels (S24)
-- Loggé pour traçabilité — immuable après création
-- =============================================================================

CREATE TABLE tirages_au_sort (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    mois            VARCHAR(7)  NOT NULL UNIQUE,
    -- Format YYYY-MM, ex: 2025-01
    nb_participants INTEGER     NOT NULL DEFAULT 0,
    formation_prix  VARCHAR(200),
    -- Nom de la formation offerte comme prix
    valeur_prix     BIGINT,
    -- Valeur en FCFA
    admin_id        UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    -- Admin qui a déclenché le tirage
    effectue_le     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gagnants_tirage (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tirage_id       UUID        NOT NULL REFERENCES tirages_au_sort(id) ON DELETE CASCADE,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id)    ON DELETE RESTRICT,
    rang            SMALLINT    NOT NULL CHECK (rang IN (1, 2, 3)),
    -- 1 = gagnant principal, 2 et 3 = consolation
    lot_description VARCHAR(300),
    notifie         BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tirage_id, rang),
    UNIQUE (tirage_id, apprenant_id)
);

CREATE INDEX idx_gagnants_tirage_id  ON gagnants_tirage(tirage_id);
CREATE INDEX idx_gagnants_apprenant  ON gagnants_tirage(apprenant_id);

COMMENT ON TABLE tirages_au_sort IS 'S24 — Tirages mensuels — immuable après création pour traçabilité';
COMMENT ON TABLE gagnants_tirage IS 'S24 — Gagnants par tirage. Rang 1 = principal, 2-3 = consolation';
SQLEOF
ok "V16__create_tirage_resultats.sql"

# =============================================================================
# V17 — LISTE D'ATTENTE (S4)
# =============================================================================
sec "V17 liste_attente"
cat > "$MIG/V17__create_liste_attente.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V17 — Liste d'attente pour les sessions complètes (S4)
-- =============================================================================

CREATE TABLE liste_attente (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    session_id      UUID        REFERENCES sessions(id)              ON DELETE CASCADE,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    -- session_id peut être NULL si l'attente concerne n'importe quelle session du cours
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                    CHECK (statut IN ('EN_ATTENTE','NOTIFIE','INSCRIT','ANNULE')),
    date_inscription TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_notification TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (apprenant_id, cours_id)
    -- Un apprenant ne peut être sur liste d'attente qu'une fois par cours
);

CREATE INDEX idx_liste_attente_cours   ON liste_attente(cours_id) WHERE statut = 'EN_ATTENTE';
CREATE INDEX idx_liste_attente_session ON liste_attente(session_id) WHERE session_id IS NOT NULL;

COMMENT ON TABLE liste_attente IS 'S4 — Liste d''attente quand toutes les sessions sont complètes';
SQLEOF
ok "V17__create_liste_attente.sql"

echo -e "\n${C_GREEN}✅  Migrations V11–V17 générées dans $MIG${C_NC}"
echo "   V11 — avis_cours          (S4)"
echo "   V12 — moratoires complet  (S17)"
echo "   V13 — creneaux            (S10)"
echo "   V14 — badges index        (S6, S13)"
echo "   V15 — parrainages         (S15)"
echo "   V16 — tirages_au_sort     (S24)"
echo "   V17 — liste_attente       (S4)"
