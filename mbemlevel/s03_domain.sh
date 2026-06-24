#!/usr/bin/env bash
# =============================================================================
# MbemNova — Script 03/15 : Couche Domain (code complet)
# =============================================================================
# RÔLE   : Écrit le code complet de toute la couche Domain.
#          Remplace les stubs créés par s02_structure.sh.
#          Zéro dépendance Spring/JPA ici — Java 21 pur.
#
# FICHIERS ÉCRITS (contenu complet) :
#   domain/shared/AggregateRoot.java
#   domain/shared/ValueObject.java
#   domain/shared/Money.java
#   domain/shared/Email.java
#   domain/shared/enums/ (7 enums)
#   domain/event/DomainEvent.java
#   domain/event/ (11 domain events)
#   domain/user/Utilisateur.java  (agrégat complet)
#   domain/user/Apprenant.java
#   domain/user/Formateur.java
#   domain/user/valueobject/ProfilTalent.java
#   domain/user/valueobject/LienParrainage.java
#
# PRÉREQUIS : s01 + s02 doivent avoir été lancés
#
# USAGE  : chmod +x s03_domain.sh && ./s03_domain.sh
# =============================================================================

set -euo pipefail
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_CYAN='\033[0;36m'
C_BOLD='\033[1m';     C_NC='\033[0m'

log_ok()  { echo -e "${C_GREEN}  [OK]${C_NC} $1"; }
log_inf() { echo -e "${C_BLUE}  [..]${C_NC} $1"; }
log_sec() { echo -e "\n${C_BOLD}${C_CYAN}── $1 ──${C_NC}"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$ROOT/src/main/java/com/mbem/mbemlevel"

echo ""
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo -e "${C_BOLD}${C_CYAN}  MbemNova · Script 03/15 · Couche Domain      ${C_NC}"
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo ""

[[ ! -f "$ROOT/pom.xml" ]]      && { echo "ERREUR: lancez s01 d'abord"; exit 1; }
[[ ! -d "$PKG/domain" ]]        && { echo "ERREUR: lancez s02 d'abord"; exit 1; }

# =============================================================================
# 1. PRIMITIVES PARTAGÉES (shared)
# =============================================================================
log_sec "1/5 Primitives partagées"

# ── AggregateRoot ─────────────────────────────────────────────────────────────
cat > "$PKG/domain/shared/AggregateRoot.java" << 'JEOF'
// =============================================================================
// MbemNova — domain/shared/AggregateRoot.java
//
// Classe de base pour TOUS les agrégats du domaine.
// ZÉRO dépendance Spring/JPA — Java pur uniquement.
//
// Un agrégat est la racine d'un groupe cohérent d'entités.
// Toute modification passe par cette racine.
// =============================================================================
package com.mbem.mbemlevel.domain.shared;

import com.mbem.mbemlevel.domain.event.DomainEvent;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Base abstraite de tous les agrégats MbemNova.
 *
 * <p><b>Domain Events</b> : Quand un fait métier important se produit
 * (paiement confirmé, certificat obtenu…), l'agrégat enregistre un
 * {@link DomainEvent}. L'infrastructure les publie <em>après</em> la
 * persistance réussie. Les handlers réagissent (emails, WhatsApp…)
 * sans couplage direct entre modules.</p>
 *
 * <p><b>Égalité</b> : Basée sur l'UUID uniquement — pas sur les attributs.</p>
 */
public abstract class AggregateRoot {

    /** Identifiant universel unique — généré à la création, jamais modifié. */
    private final UUID id;

    /** Date de création — immuable après construction. */
    private final LocalDateTime createdAt;

    /** Date de dernière modification — mise à jour via {@link #markUpdated()}. */
    private LocalDateTime updatedAt;

    /**
     * Events de domaine en attente de publication.
     * {@code transient} : jamais persisté ni sérialisé.
     */
    private final transient List<DomainEvent> domainEvents = new ArrayList<>();

    // ── Constructeurs ─────────────────────────────────────────────────────────

    /** Constructeur pour une NOUVELLE entité (génère UUID + timestamps). */
    protected AggregateRoot() {
        this.id        = UUID.randomUUID();
        this.createdAt = LocalDateTime.now();
        this.updatedAt = this.createdAt;
    }

    /**
     * Constructeur de RECONSTITUTION depuis la persistance.
     * Utilisé exclusivement par les mappers JPA — ne jamais appeler directement.
     */
    protected AggregateRoot(UUID id, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id        = Objects.requireNonNull(id,        "id ne peut pas être null");
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt ne peut pas être null");
        this.updatedAt = updatedAt != null ? updatedAt : createdAt;
    }

    // ── Domain Events ─────────────────────────────────────────────────────────

    /**
     * Enregistre un event à publier après la persistance.
     *
     * <pre>{@code
     * // Dans Utilisateur.creer() :
     * registerEvent(new ApprenantInscritEvent(getId(), prenom, email));
     * }</pre>
     */
    protected void registerEvent(DomainEvent event) {
        Objects.requireNonNull(event, "L'event ne peut pas être null");
        this.domainEvents.add(event);
    }

    /** Vue non-modifiable des events en attente. */
    public List<DomainEvent> getDomainEvents() {
        return Collections.unmodifiableList(domainEvents);
    }

    /** Vide les events après leur publication par l'infrastructure. */
    public void clearDomainEvents() {
        this.domainEvents.clear();
    }

    /** @return true si des events n'ont pas encore été publiés. */
    public boolean hasUnpublishedEvents() {
        return !this.domainEvents.isEmpty();
    }

    // ── Horodatage ────────────────────────────────────────────────────────────

    /**
     * Marque l'agrégat comme modifié.
     * À appeler dans chaque méthode qui change l'état de l'agrégat.
     */
    protected void markUpdated() {
        this.updatedAt = LocalDateTime.now();
    }

    // ── Égalité par identifiant ───────────────────────────────────────────────

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        return Objects.equals(id, ((AggregateRoot) o).id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    @Override
    public String toString() {
        return "%s{id=%s}".formatted(getClass().getSimpleName(), id);
    }

    // ── Accesseurs ────────────────────────────────────────────────────────────

    public UUID          getId()        { return id; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
JEOF
log_ok "AggregateRoot.java"

# ── ValueObject ───────────────────────────────────────────────────────────────
cat > "$PKG/domain/shared/ValueObject.java" << 'JEOF'
// =============================================================================
// MbemNova — domain/shared/ValueObject.java
// =============================================================================
package com.mbem.mbemlevel.domain.shared;

/**
 * Marqueur pour les Value Objects du domaine.
 *
 * <p>Un Value Object est immuable et défini par ses attributs (pas par une identité).
 * Toute opération retourne un nouvel objet — jamais de mutation.</p>
 *
 * <p><b>Exemples MbemNova</b> : {@code Money}, {@code Email},
 * {@code ProfilTalent}, {@code LienParrainage}.</p>
 */
public interface ValueObject {
    // Marqueur — pas de méthodes obligatoires.
    // L'immuabilité est une convention, pas une contrainte Java.
}
JEOF
log_ok "ValueObject.java"

# ── Money ─────────────────────────────────────────────────────────────────────
cat > "$PKG/domain/shared/Money.java" << 'JEOF'
// =============================================================================
// MbemNova — domain/shared/Money.java
//
// Value Object représentant un montant monétaire en FCFA (XAF).
// Immuable — toute opération retourne un nouvel objet.
// Utilise BigDecimal pour éviter les erreurs d'arrondi des double.
// =============================================================================
package com.mbem.mbemlevel.domain.shared;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.NumberFormat;
import java.util.Locale;
import java.util.Objects;

/**
 * Montant monétaire en FCFA (Franc CFA Afrique Centrale — XAF).
 *
 * <h3>Pourquoi pas un simple long ?</h3>
 * <p>Un {@code long} force l'appelant à gérer lui-même les règles métier
 * (non-négatif, calcul de pourcentage…). {@code Money} les encapsule
 * et garantit leur respect à la construction.</p>
 *
 * <h3>Exemple d'utilisation</h3>
 * <pre>{@code
 * Money prix    = Money.of(50_000);         // 50 000 FCFA
 * Money acompte = prix.pct(30);             // 15 000 FCFA
 * Money reste   = prix.minus(acompte);      // 35 000 FCFA
 * prix.toDisplay();                          // "50 000 FCFA"
 * }</pre>
 */
public final class Money implements ValueObject {

    /** Devise fixe — FCFA Afrique Centrale. */
    public static final String DEVISE = "XAF";

    /** Constante zéro — utiliser plutôt que {@code Money.of(0)}. */
    public static final Money ZERO = new Money(BigDecimal.ZERO);

    private final BigDecimal amount;

    // ── Construction ──────────────────────────────────────────────────────────

    private Money(BigDecimal amount) {
        if (amount == null) {
            throw new IllegalArgumentException("Le montant ne peut pas être null");
        }
        if (amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Le montant ne peut pas être négatif : " + amount);
        }
        // Toujours 2 décimales pour la cohérence interne
        this.amount = amount.setScale(2, RoundingMode.HALF_UP);
    }

    /** Crée depuis un entier (cas courant en FCFA sans décimale). */
    public static Money of(long amount) {
        return new Money(BigDecimal.valueOf(amount));
    }

    /** Crée depuis un BigDecimal (résultats de calculs). */
    public static Money of(BigDecimal amount) {
        return new Money(amount);
    }

    // ── Opérations arithmétiques ──────────────────────────────────────────────

    /** Addition — retourne un nouveau {@code Money}. */
    public Money plus(Money other) {
        return new Money(this.amount.add(requireNonNull(other).amount));
    }

    /**
     * Soustraction — retourne un nouveau {@code Money}.
     * @throws IllegalArgumentException si le résultat serait négatif.
     */
    public Money minus(Money other) {
        return new Money(this.amount.subtract(requireNonNull(other).amount));
    }

    /**
     * Calcule un pourcentage de ce montant.
     * @param percentage Valeur entre 0.0 et 100.0 (ex: 30.0 pour 30%)
     */
    public Money pct(double percentage) {
        if (percentage < 0 || percentage > 100) {
            throw new IllegalArgumentException(
                "Pourcentage invalide : " + percentage + " (doit être entre 0 et 100)");
        }
        return new Money(
            this.amount
                .multiply(BigDecimal.valueOf(percentage / 100.0))
                .setScale(2, RoundingMode.HALF_UP)
        );
    }

    // ── Comparaisons ─────────────────────────────────────────────────────────

    public boolean isZero()                    { return amount.compareTo(BigDecimal.ZERO) == 0; }
    public boolean isPositive()                { return amount.compareTo(BigDecimal.ZERO) > 0; }
    public boolean isGreaterThan(Money other)  { return amount.compareTo(requireNonNull(other).amount) > 0; }
    public boolean isGreaterOrEq(Money other)  { return amount.compareTo(requireNonNull(other).amount) >= 0; }
    public boolean isLessThan(Money other)     { return amount.compareTo(requireNonNull(other).amount) < 0; }

    // ── Accesseurs ────────────────────────────────────────────────────────────

    public BigDecimal getAmount() { return amount; }

    /** Retourne le montant arrondi en entier (FCFA sans centimes). */
    public long toLong() {
        return amount.setScale(0, RoundingMode.HALF_UP).longValueExact();
    }

    /** Format d'affichage localisé : "50 000 FCFA". */
    public String toDisplay() {
        NumberFormat nf = NumberFormat.getNumberInstance(Locale.FRENCH);
        nf.setMaximumFractionDigits(0);
        return nf.format(amount) + " FCFA";
    }

    // ── Equals / hashCode / toString ─────────────────────────────────────────

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Money m)) return false;
        return amount.compareTo(m.amount) == 0; // compareTo ignorant les trailing zeros
    }

    @Override
    public int hashCode() {
        return Objects.hash(amount.stripTrailingZeros());
    }

    @Override
    public String toString() {
        return amount + " " + DEVISE;
    }

    private static Money requireNonNull(Money m) {
        return Objects.requireNonNull(m, "L'autre montant ne peut pas être null");
    }
}
JEOF
log_ok "Money.java"

# ── Email Value Object ────────────────────────────────────────────────────────
cat > "$PKG/domain/shared/Email.java" << 'JEOF'
// =============================================================================
// MbemNova — domain/shared/Email.java
// =============================================================================
package com.mbem.mbemlevel.domain.shared;

import java.util.Objects;

/**
 * Value Object représentant une adresse email validée.
 * Immuable — normalisée en minuscules à la construction.
 */
public final class Email implements ValueObject {

    private final String value;

    private Email(String value) {
        Objects.requireNonNull(value, "L'adresse email ne peut pas être null");
        String trimmed = value.trim().toLowerCase();
        if (trimmed.isEmpty()) {
            throw new IllegalArgumentException("L'adresse email ne peut pas être vide");
        }
        // Validation minimale dans le domaine — Bean Validation gère le format HTTP
        if (!trimmed.contains("@") || !trimmed.contains(".")) {
            throw new IllegalArgumentException("Format d'email invalide : " + value);
        }
        if (trimmed.length() > 255) {
            throw new IllegalArgumentException("Email trop long (max 255 chars)");
        }
        this.value = trimmed;
    }

    public static Email of(String value) {
        return new Email(value);
    }

    public String getValue() { return value; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Email e)) return false;
        return value.equals(e.value);
    }

    @Override
    public int hashCode() { return Objects.hash(value); }

    @Override
    public String toString() { return value; }
}
JEOF
log_ok "Email.java"

# =============================================================================
# 2. ENUMS
# =============================================================================
log_sec "2/5 Enums"

cat > "$PKG/domain/shared/enums/Role.java" << 'JEOF'
// MbemNova — domain/shared/enums/Role.java
package com.mbem.mbemlevel.domain.shared.enums;

/**
 * Rôles utilisateurs MbemNova.
 * L'ordinal encode le niveau de privilège (croissant).
 */
public enum Role {
    /** Rôle par défaut à l'inscription — suit des cours. */
    APPRENANT,
    /** Crée des cours, gère des sessions, corrige des devoirs. */
    FORMATEUR,
    /** Gestion complète : paiements, inscriptions, statistiques. */
    ADMIN,
    /** Rôle technique maximal — gère les admins. Maximum 2 personnes. */
    SUPER_ADMIN;

    /** Préfixe requis par Spring Security pour @PreAuthorize. */
    public String toSpringRole() {
        return "ROLE_" + this.name();
    }

    /**
     * Ce rôle a-t-il au moins les droits du rôle cible ?
     * Exemple : {@code ADMIN.hasAtLeast(FORMATEUR)} → true
     */
    public boolean hasAtLeast(Role target) {
        return this.ordinal() >= target.ordinal();
    }
}
JEOF

cat > "$PKG/domain/shared/enums/StatutApprenant.java" << 'JEOF'
// MbemNova — domain/shared/enums/StatutApprenant.java
package com.mbem.mbemlevel.domain.shared.enums;

/**
 * Cycle de vie du compte apprenant.
 * <pre>
 * INSCRIT → ACTIF (premier cours commencé)
 * ACTIF   → SUSPENDU (J+10 sans paiement)
 * SUSPENDU→ ACTIF (après régularisation)
 * ACTIF   → CERTIFIE (premier certificat obtenu)
 * </pre>
 */
public enum StatutApprenant {
    /** Compte créé, aucun cours commencé. */
    INSCRIT,
    /** En cours d'apprentissage, paiements à jour. */
    ACTIF,
    /** Accès cours bloqué — retard paiement. Progression préservée. */
    SUSPENDU,
    /** A obtenu au moins un certificat. */
    CERTIFIE
}
JEOF

cat > "$PKG/domain/shared/enums/StatutPaiement.java" << 'JEOF'
// MbemNova — domain/shared/enums/StatutPaiement.java
package com.mbem.mbemlevel.domain.shared.enums;

/**
 * Statut d'une tranche de paiement.
 * <pre>
 * EN_ATTENTE → PAYE (admin confirme)
 * EN_ATTENTE → EN_RETARD (échéance dépassée)
 * EN_RETARD  → PAYE (après régularisation)
 * EN_ATTENTE → MORATOIRE (délai accordé)
 * </pre>
 */
public enum StatutPaiement {
    EN_ATTENTE, PAYE, EN_RETARD, MORATOIRE, ANNULE
}
JEOF

cat > "$PKG/domain/shared/enums/ModePaiement.java" << 'JEOF'
// MbemNova — domain/shared/enums/ModePaiement.java
package com.mbem.mbemlevel.domain.shared.enums;

/**
 * Modes de paiement acceptés.
 * CASH : actif dès le lancement.
 * MOBILE_MONEY / ONLINE : Phase 2.
 */
public enum ModePaiement {
    /** Paiement physique — activé manuellement par l'admin. */
    CASH,
    /** MTN Money ou Orange Money. */
    MOBILE_MONEY,
    /** Carte bancaire via Stripe/PayDunya. */
    ONLINE
}
JEOF

cat > "$PKG/domain/shared/enums/NiveauCours.java" << 'JEOF'
// MbemNova — domain/shared/enums/NiveauCours.java
package com.mbem.mbemlevel.domain.shared.enums;

/** Niveau de difficulté d'un cours. */
public enum NiveauCours { DEBUTANT, INTERMEDIAIRE, AVANCE }
JEOF

cat > "$PKG/domain/shared/enums/Modalite.java" << 'JEOF'
// MbemNova — domain/shared/enums/Modalite.java
package com.mbem.mbemlevel.domain.shared.enums;

/** Modalité d'une session de formation. */
public enum Modalite {
    /** En présentiel dans les locaux MbemNova. */
    PRESENTIEL,
    /** En ligne via Google Meet ou Zoom. */
    ONLINE_MEET
}
JEOF

cat > "$PKG/domain/shared/enums/CanalNotification.java" << 'JEOF'
// MbemNova — domain/shared/enums/CanalNotification.java
package com.mbem.mbemlevel.domain.shared.enums;

/** Canal de distribution d'une notification. */
public enum CanalNotification { EMAIL, WHATSAPP, IN_APP }
JEOF

cat > "$PKG/domain/shared/enums/TypeNotification.java" << 'JEOF'
// MbemNova — domain/shared/enums/TypeNotification.java
package com.mbem.mbemlevel.domain.shared.enums;

/** Type sémantique d'une notification (utilisé pour l'affichage in-app). */
public enum TypeNotification {
    RAPPEL, BADGE, RELANCE_PAIEMENT,
    DEVOIR_DISPONIBLE, RENDU_CORRIGE,
    CERTIFICAT, INFO
}
JEOF

log_ok "7 enums"

# =============================================================================
# 3. DOMAIN EVENTS
# =============================================================================
log_sec "3/5 Domain Events"

cat > "$PKG/domain/event/DomainEvent.java" << 'JEOF'
// =============================================================================
// MbemNova — domain/event/DomainEvent.java
//
// Interface de base pour tous les domain events.
// Les events sont créés dans les agrégats, publiés par l'infrastructure
// APRÈS la persistance, et traités par les handlers de la couche Application.
// =============================================================================
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Interface marqueur pour tous les domain events MbemNova.
 *
 * <h3>Cycle de vie</h3>
 * <pre>
 * Agrégat → registerEvent(e) → save() → publishEvent(e) → Handler
 * </pre>
 *
 * <h3>Implémentation recommandée (Java Record)</h3>
 * <pre>{@code
 * public record MonEvent(UUID entityId, String info, UUID eventId, LocalDateTime at)
 *     implements DomainEvent {
 *   public MonEvent(UUID id, String info) {
 *     this(id, info, UUID.randomUUID(), LocalDateTime.now());
 *   }
 *   public UUID getEventId() { return eventId; }
 *   public LocalDateTime getOccurredAt() { return at; }
 *   public String getEventType() { return "MON_EVENT"; }
 * }
 * }</pre>
 */
public interface DomainEvent {
    /** Identifiant unique de cet event (pour la déduplication). */
    UUID getEventId();
    /** Horodatage de l'occurrence. */
    LocalDateTime getOccurredAt();
    /** Nom SCREAMING_SNAKE_CASE du type d'event (pour le monitoring). */
    String getEventType();
}
JEOF

# Macro pour écrire rapidement les events (tous sont des Records)
write_event() {
  local name="$1" type="$2" fields="$3" ctor_params="$4" ctor_body="$5" desc="$6"
  cat > "$PKG/domain/event/${name}.java" << JEOF
// MbemNova — domain/event/${name}.java
// ${desc}
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : ${desc}
 * Type  : ${type}
 */
public record ${name}(${fields}, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public ${name}(${ctor_params}) {
        this(${ctor_body}, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "${type}"; }
}
JEOF
}

write_event "ApprenantInscritEvent" "APPRENANT_INSCRIT" \
  "UUID apprenantId, String prenom, String email" \
  "UUID apprenantId, String prenom, String email" \
  "apprenantId, prenom, email" \
  "Nouvel apprenant inscrit — déclenche email bienvenue + rappel 48h"

write_event "SeuilPaiementAtteintEvent" "SEUIL_PAIEMENT_ATTEINT" \
  "UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours, double pctActuel" \
  "UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours, double pctActuel" \
  "apprenantId, coursId, prenom, email, telephone, nomCours, pctActuel" \
  "Seuil de conversion atteint — déclenche email nurturing + WhatsApp J+1"

write_event "PaiementConfirmeEvent" "PAIEMENT_CONFIRME" \
  "UUID paiementId, UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours" \
  "UUID paiementId, UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours" \
  "paiementId, apprenantId, coursId, prenom, email, telephone, nomCours" \
  "Paiement confirmé — active accès complet + génère facture PDF"

write_event "CoursTermineEvent" "COURS_TERMINE" \
  "UUID apprenantId, UUID coursId, String prenom, String email, String nomCours" \
  "UUID apprenantId, UUID coursId, String prenom, String email, String nomCours" \
  "apprenantId, coursId, prenom, email, nomCours" \
  "Toutes leçons et QCM validés — déclenche génération du certificat"

write_event "CertificatObtenuEvent" "CERTIFICAT_OBTENU" \
  "UUID certificatId, UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours, String codeVerif" \
  "UUID certificatId, UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours, String codeVerif" \
  "certificatId, apprenantId, coursId, prenom, email, telephone, nomCours, codeVerif" \
  "Certificat généré — email + WhatsApp + mise à jour profil talent"

write_event "PaiementEnRetardEvent" "PAIEMENT_EN_RETARD" \
  "UUID paiementId, UUID apprenantId, String prenom, String email, String telephone, int joursRetard" \
  "UUID paiementId, UUID apprenantId, String prenom, String email, String telephone, int joursRetard" \
  "paiementId, apprenantId, prenom, email, telephone, joursRetard" \
  "Échéance dépassée — déclenche relances automatiques J+3 J+7 J+10"

write_event "CompteSuspenduEvent" "COMPTE_SUSPENDU" \
  "UUID apprenantId, String prenom, String email, String messagePersonnalise" \
  "UUID apprenantId, String prenom, String email, String messagePersonnalise" \
  "apprenantId, prenom, email, messagePersonnalise" \
  "Compte suspendu J+10 — email suspension + notification admin"

write_event "CompteReactiveEvent" "COMPTE_REACTIVE" \
  "UUID apprenantId, String prenom, String email" \
  "UUID apprenantId, String prenom, String email" \
  "apprenantId, prenom, email" \
  "Compte réactivé après régularisation du paiement"

write_event "DevoirPublieEvent" "DEVOIR_PUBLIE" \
  "UUID devoirId, UUID sessionId, String nomDevoir, String dateRemise" \
  "UUID devoirId, UUID sessionId, String nomDevoir, String dateRemise" \
  "devoirId, sessionId, nomDevoir, dateRemise" \
  "Formateur a publié un devoir — notifie les apprenants"

write_event "RenduCorrigeEvent" "RENDU_CORRIGE" \
  "UUID renduId, UUID apprenantId, String prenom, String email, int note" \
  "UUID renduId, UUID apprenantId, String prenom, String email, int note" \
  "renduId, apprenantId, prenom, email, note" \
  "Formateur a noté le rendu — notifie l'apprenant"

write_event "ParrainageActiveEvent" "PARRAINAGE_ACTIVE" \
  "UUID parrainId, UUID filleulId, String emailParrain" \
  "UUID parrainId, UUID filleulId, String emailParrain" \
  "parrainId, filleulId, emailParrain" \
  "Filleul a complété son premier module — active la récompense parrain"

log_ok "DomainEvent interface + 11 events"

# =============================================================================
# 4. AGRÉGAT UTILISATEUR (le plus complexe du domaine)
# =============================================================================
log_sec "4/5 Agrégat Utilisateur"

cat > "$PKG/domain/user/Utilisateur.java" << 'JEOF'
// =============================================================================
// MbemNova — domain/user/Utilisateur.java
//
// Agrégat racine de tous les utilisateurs de la plateforme.
// ZÉRO annotation Spring/JPA — Java 21 pur.
//
// Toutes les règles métier liées aux utilisateurs sont ici.
// Les services ne contiennent que de l'orchestration.
// =============================================================================
package com.mbem.mbemlevel.domain.user;

import com.mbem.mbemlevel.domain.event.ApprenantInscritEvent;
import com.mbem.mbemlevel.domain.event.CompteSuspenduEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.shared.enums.StatutApprenant;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Agrégat racine Utilisateur.
 *
 * <h3>Règles métier encapsulées</h3>
 * <ul>
 *   <li>Un compte bloqué (brute force) ne peut pas se connecter</li>
 *   <li>Un compte suspendu peut se connecter mais pas accéder aux cours</li>
 *   <li>Un SUPER_ADMIN ne peut être modifié que par un autre SUPER_ADMIN</li>
 *   <li>L'email est immuable après création</li>
 *   <li>Le mot de passe est TOUJOURS haché — jamais en clair dans cet objet</li>
 * </ul>
 *
 * <h3>Pattern Factory Method</h3>
 * <p>Utiliser {@link #creer(String, String, String)} pour créer un nouvel utilisateur.
 * Le constructeur public de reconstitution est réservé aux mappers JPA.</p>
 */
public class Utilisateur extends AggregateRoot {

    /** Prénom affiché dans l'interface et les emails. */
    private String prenom;
    /** Nom de famille (optionnel à l'inscription). */
    private String nom;
    /**
     * Email — identifiant unique et immuable.
     * Un changement d'email nécessite un processus dédié avec vérification.
     */
    private final String email;
    /**
     * Hash BCrypt du mot de passe (cost=12).
     * JAMAIS stocker en clair. JAMAIS logger.
     */
    private String motDePasseHache;
    private Role role;
    private StatutApprenant statut;

    // ── Sécurité connexion ────────────────────────────────────────────────────
    /** Réinitialisé à 0 après chaque connexion réussie. */
    private int tentativesEchouees;
    /** Non null = blocage temporaire actif (brute force). */
    private LocalDateTime bloqueJusquAu;
    /** Mise à jour après chaque connexion réussie. */
    private LocalDateTime derniereConnexion;

    // ── Vérification email ────────────────────────────────────────────────────
    private boolean emailVerifie;
    /** Token envoyé par email, nullifié après vérification. */
    private String tokenVerificationEmail;

    // ── Téléphone (optionnel) ─────────────────────────────────────────────────
    private String telephone;

    // =========================================================================
    // FACTORY METHOD — Point d'entrée unique pour créer un utilisateur
    // =========================================================================

    /**
     * Crée un nouvel apprenant avec profil minimal.
     *
     * <p>Garantit que :
     * <ul>
     *   <li>Les données sont validées avant création</li>
     *   <li>Le rôle est APPRENANT et le statut INSCRIT</li>
     *   <li>L'event ApprenantInscritEvent est enregistré</li>
     * </ul>
     *
     * @param prenom          Prénom (2–50 chars)
     * @param email           Email unique en minuscules
     * @param motDePasseHache Hash BCrypt — JAMAIS le mot de passe en clair
     */
    public static Utilisateur creer(String prenom, String email, String motDePasseHache) {
        validatePrenom(prenom);
        validateEmail(email);
        Objects.requireNonNull(motDePasseHache, "Le hash du mot de passe est obligatoire");

        Utilisateur u = new Utilisateur(email.trim().toLowerCase());
        u.prenom             = prenom.trim();
        u.motDePasseHache    = motDePasseHache;
        u.role               = Role.APPRENANT;
        u.statut             = StatutApprenant.INSCRIT;
        u.emailVerifie       = false;
        u.tentativesEchouees = 0;

        // Event publié après persistance → déclenche email bienvenue
        u.registerEvent(new ApprenantInscritEvent(u.getId(), u.prenom, u.email));
        return u;
    }

    /**
     * Constructeur de reconstitution depuis la persistance.
     * RÉSERVÉ aux mappers JPA — ne pas appeler dans le code métier.
     */
    public Utilisateur(UUID id, String prenom, String nom, String email,
                       String motDePasseHache, Role role, StatutApprenant statut,
                       int tentativesEchouees, LocalDateTime bloqueJusquAu,
                       LocalDateTime derniereConnexion, boolean emailVerifie,
                       String tokenVerificationEmail, String telephone,
                       LocalDateTime createdAt, LocalDateTime updatedAt) {
        super(id, createdAt, updatedAt);
        this.prenom                   = prenom;
        this.nom                      = nom;
        this.email                    = email;
        this.motDePasseHache          = motDePasseHache;
        this.role                     = role;
        this.statut                   = statut;
        this.tentativesEchouees       = tentativesEchouees;
        this.bloqueJusquAu            = bloqueJusquAu;
        this.derniereConnexion        = derniereConnexion;
        this.emailVerifie             = emailVerifie;
        this.tokenVerificationEmail   = tokenVerificationEmail;
        this.telephone                = telephone;
    }

    /** Constructeur privé utilisé par la factory method. */
    private Utilisateur(String email) {
        super();
        this.email = email;
    }

    // =========================================================================
    // COMPORTEMENTS MÉTIER
    // =========================================================================

    /**
     * Enregistre une connexion réussie.
     * Réinitialise le compteur d'échecs et lève le blocage éventuel.
     */
    public void enregistrerConnexionReussie() {
        this.derniereConnexion  = LocalDateTime.now();
        this.tentativesEchouees = 0;
        this.bloqueJusquAu      = null;
        // Première connexion après inscription → passer INSCRIT → ACTIF
        if (this.statut == StatutApprenant.INSCRIT) {
            this.statut = StatutApprenant.ACTIF;
        }
        markUpdated();
    }

    /**
     * Enregistre une tentative de connexion échouée.
     * Bloque temporairement le compte après {@code maxTentatives} échecs.
     *
     * @param maxTentatives       Seuil avant blocage (ex: 5)
     * @param dureeBlockageMinutes Durée du blocage temporaire (ex: 30)
     */
    public void enregistrerConnexionEchouee(int maxTentatives, int dureeBlockageMinutes) {
        this.tentativesEchouees++;
        if (this.tentativesEchouees >= maxTentatives) {
            this.bloqueJusquAu = LocalDateTime.now().plusMinutes(dureeBlockageMinutes);
        }
        markUpdated();
    }

    /**
     * Vérifie si le compte est temporairement bloqué (brute force).
     * Le blocage expire automatiquement.
     */
    public boolean estBloque() {
        if (bloqueJusquAu == null) return false;
        boolean encoreBloque = LocalDateTime.now().isBefore(bloqueJusquAu);
        if (!encoreBloque) {
            // Auto-expiration silencieuse
            this.bloqueJusquAu      = null;
            this.tentativesEchouees = 0;
        }
        return encoreBloque;
    }

    /**
     * L'utilisateur peut-il se connecter ?
     * Note : un compte SUSPENDU peut se connecter (pour voir le message de suspension),
     * mais ne peut pas accéder aux cours ({@link #peutAccederAuxCours()}).
     */
    public boolean peutSeConnecter() {
        return !estBloque();
    }

    /** L'utilisateur peut-il accéder au contenu des cours ? */
    public boolean peutAccederAuxCours() {
        return this.statut != StatutApprenant.SUSPENDU && !estBloque();
    }

    /**
     * Suspend le compte pour retard de paiement.
     * La progression est intégralement préservée.
     *
     * @param messageAdmin Message personnalisé pour l'apprenant (peut être null)
     */
    public void suspendre(String messageAdmin) {
        if (this.statut == StatutApprenant.SUSPENDU) {
            throw new IllegalStateException("Le compte " + getId() + " est déjà suspendu");
        }
        this.statut = StatutApprenant.SUSPENDU;
        markUpdated();

        String msg = messageAdmin != null ? messageAdmin
            : "Votre accès a été suspendu suite à un retard de paiement.";
        registerEvent(new CompteSuspenduEvent(getId(), prenom, email, msg));
    }

    /** Réactive le compte après régularisation du paiement. */
    public void reactiver() {
        this.statut        = StatutApprenant.ACTIF;
        this.bloqueJusquAu = null;
        markUpdated();
    }

    /** Marque l'email comme vérifié (après clic sur le lien de confirmation). */
    public void verifierEmail() {
        this.emailVerifie             = true;
        this.tokenVerificationEmail   = null;
        markUpdated();
    }

    /**
     * Change le rôle de cet utilisateur.
     *
     * @param nouveauRole    Rôle à attribuer
     * @param roleExecutant  Rôle de l'admin qui effectue l'opération
     * @throws IllegalArgumentException si les droits sont insuffisants
     */
    public void changerRole(Role nouveauRole, Role roleExecutant) {
        Objects.requireNonNull(nouveauRole,   "Le nouveau rôle est obligatoire");
        Objects.requireNonNull(roleExecutant, "Le rôle exécutant est obligatoire");

        // Modifier un SUPER_ADMIN requiert d'être SUPER_ADMIN
        if (this.role == Role.SUPER_ADMIN && roleExecutant != Role.SUPER_ADMIN) {
            throw new IllegalArgumentException(
                "Seul un SUPER_ADMIN peut modifier le rôle d'un SUPER_ADMIN");
        }
        // Attribuer SUPER_ADMIN requiert d'être SUPER_ADMIN
        if (nouveauRole == Role.SUPER_ADMIN && roleExecutant != Role.SUPER_ADMIN) {
            throw new IllegalArgumentException(
                "Seul un SUPER_ADMIN peut attribuer le rôle SUPER_ADMIN");
        }
        this.role = nouveauRole;
        markUpdated();
    }

    /**
     * Met à jour le mot de passe haché.
     * Appeler {@code refreshTokenService.revokerTous()} après cet appel.
     *
     * @param nouveauHashBcrypt Nouveau hash BCrypt — JAMAIS le mot de passe en clair
     */
    public void changerMotDePasse(String nouveauHashBcrypt) {
        if (nouveauHashBcrypt == null || nouveauHashBcrypt.isBlank()) {
            throw new IllegalArgumentException("Le nouveau hash est obligatoire");
        }
        this.motDePasseHache = nouveauHashBcrypt;
        markUpdated();
    }

    /** Met à jour le prénom et/ou le nom. L'email n'est pas modifiable ici. */
    public void mettreAJourProfil(String prenom, String nom, String telephone) {
        if (prenom != null && !prenom.isBlank()) {
            validatePrenom(prenom);
            this.prenom = prenom.trim();
        }
        if (nom != null)       this.nom       = nom.trim().isEmpty() ? null : nom.trim();
        if (telephone != null) this.telephone = telephone.trim().isEmpty() ? null : telephone.trim();
        markUpdated();
    }

    // =========================================================================
    // VALIDATIONS PRIVÉES
    // =========================================================================

    private static void validatePrenom(String prenom) {
        if (prenom == null || prenom.isBlank()) {
            throw new IllegalArgumentException("Le prénom est obligatoire");
        }
        if (prenom.trim().length() < 2) {
            throw new IllegalArgumentException("Le prénom doit contenir au moins 2 caractères");
        }
        if (prenom.trim().length() > 50) {
            throw new IllegalArgumentException("Le prénom ne peut pas dépasser 50 caractères");
        }
    }

    private static void validateEmail(String email) {
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("L'email est obligatoire");
        }
        String t = email.trim().toLowerCase();
        if (!t.contains("@") || !t.contains(".")) {
            throw new IllegalArgumentException("Format d'email invalide : " + email);
        }
        if (t.length() > 255) {
            throw new IllegalArgumentException("L'email ne peut pas dépasser 255 caractères");
        }
    }

    // =========================================================================
    // ACCESSEURS — Pas de setters publics : tout passe par les méthodes métier
    // =========================================================================

    public String          getPrenom()                    { return prenom; }
    public String          getNom()                       { return nom; }
    public String          getNomComplet()                { return prenom + (nom != null ? " " + nom : ""); }
    public String          getEmail()                     { return email; }
    public String          getMotDePasseHache()           { return motDePasseHache; }
    public Role            getRole()                      { return role; }
    public StatutApprenant getStatut()                    { return statut; }
    public int             getTentativesEchouees()        { return tentativesEchouees; }
    public LocalDateTime   getBloqueJusquAu()             { return bloqueJusquAu; }
    public LocalDateTime   getDerniereConnexion()         { return derniereConnexion; }
    public boolean         isEmailVerifie()               { return emailVerifie; }
    public String          getTokenVerificationEmail()    { return tokenVerificationEmail; }
    public String          getTelephone()                 { return telephone; }

    /** Setter limité pour le token de vérification email (appelé par le use case). */
    public void setTokenVerificationEmail(String token) {
        this.tokenVerificationEmail = token;
    }
}
JEOF
log_ok "Utilisateur.java (agrégat complet)"

# =============================================================================
# 5. VALUE OBJECTS User + Entités simples du domaine User
# =============================================================================
log_sec "5/5 Value Objects User"

cat > "$PKG/domain/user/Apprenant.java" << 'JEOF'
// MbemNova — domain/user/Apprenant.java
package com.mbem.mbemlevel.domain.user;

import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.shared.enums.StatutApprenant;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Extension de {@link Utilisateur} avec les données spécifiques
 * à un apprenant : XP, streak, rang, profil talent.
 */
public class Apprenant extends Utilisateur {

    private int xpTotal;
    private int streakJours;
    private Integer rangPlateforme;
    private boolean disponiblePourEmploi;

    /** Constructeur de reconstitution JPA. */
    public Apprenant(UUID id, String prenom, String nom, String email,
                     String motDePasseHache, StatutApprenant statut,
                     int tentativesEchouees, LocalDateTime bloqueJusquAu,
                     LocalDateTime derniereConnexion, boolean emailVerifie,
                     String tokenVerif, String telephone,
                     LocalDateTime createdAt, LocalDateTime updatedAt,
                     int xpTotal, int streakJours, Integer rangPlateforme,
                     boolean disponiblePourEmploi) {
        super(id, prenom, nom, email, motDePasseHache, Role.APPRENANT, statut,
              tentativesEchouees, bloqueJusquAu, derniereConnexion, emailVerifie,
              tokenVerif, telephone, createdAt, updatedAt);
        this.xpTotal              = xpTotal;
        this.streakJours          = streakJours;
        this.rangPlateforme       = rangPlateforme;
        this.disponiblePourEmploi = disponiblePourEmploi;
    }

    /** Ajoute des XP et met à jour le streak. */
    public void ajouterXP(int xp) {
        if (xp < 0) throw new IllegalArgumentException("XP ne peut pas être négatif");
        this.xpTotal += xp;
        markUpdated();
    }

    public void incrementerStreak() { this.streakJours++; markUpdated(); }
    public void resetStreak()       { this.streakJours = 0; markUpdated(); }

    public void setDisponible(boolean disponible) {
        this.disponiblePourEmploi = disponible;
        markUpdated();
    }

    public int     getXpTotal()              { return xpTotal; }
    public int     getStreakJours()          { return streakJours; }
    public Integer getRangPlateforme()       { return rangPlateforme; }
    public boolean isDisponiblePourEmploi()  { return disponiblePourEmploi; }
}
JEOF

cat > "$PKG/domain/user/Formateur.java" << 'JEOF'
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
                     String tokenVerif, String telephone,
                     LocalDateTime createdAt, LocalDateTime updatedAt,
                     String specialite, String biographie, Double noteGlobale) {
        super(id, prenom, nom, email, motDePasseHache, Role.FORMATEUR, statut,
              tentativesEchouees, bloqueJusquAu, derniereConnexion, emailVerifie,
              tokenVerif, telephone, createdAt, updatedAt);
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
JEOF

cat > "$PKG/domain/user/valueobject/ProfilTalent.java" << 'JEOF'
// MbemNova — domain/user/valueobject/ProfilTalent.java
package com.mbem.mbemlevel.domain.user.valueobject;

import com.mbem.mbemlevel.domain.shared.ValueObject;

/**
 * Value Object représentant le profil public d'un apprenant
 * dans la vitrine Talents (visible par les recruteurs).
 * Immuable — utiliser withXxx() pour créer des variantes.
 */
public record ProfilTalent(
    String ville,
    String bio,
    String lienPortfolio,
    String lienCv,
    String lienLinkedin,
    String lienGithub,
    boolean disponiblePourEmploi
) implements ValueObject {

    /** ProfilTalent vide — valeur par défaut à l'inscription. */
    public static ProfilTalent vide() {
        return new ProfilTalent(null, null, null, null, null, null, false);
    }

    public ProfilTalent withDisponible(boolean dispo) {
        return new ProfilTalent(ville, bio, lienPortfolio, lienCv, lienLinkedin, lienGithub, dispo);
    }
}
JEOF

cat > "$PKG/domain/user/valueobject/LienParrainage.java" << 'JEOF'
// MbemNova — domain/user/valueobject/LienParrainage.java
package com.mbem.mbemlevel.domain.user.valueobject;

import com.mbem.mbemlevel.domain.shared.ValueObject;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.Objects;

/**
 * Value Object — code de parrainage unique.
 * Immuable. Généré aléatoirement à la demande.
 */
public record LienParrainage(String code) implements ValueObject {

    private static final SecureRandom RANDOM = new SecureRandom();

    public LienParrainage {
        Objects.requireNonNull(code, "Le code de parrainage ne peut pas être null");
        if (code.isBlank() || code.length() < 6) {
            throw new IllegalArgumentException("Code de parrainage invalide : " + code);
        }
    }

    /** Génère un code de parrainage aléatoire de 8 caractères URL-safe. */
    public static LienParrainage generer() {
        byte[] bytes = new byte[6];
        RANDOM.nextBytes(bytes);
        String code = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes).toUpperCase();
        return new LienParrainage(code.substring(0, 8));
    }

    /** URL complète du lien de parrainage. */
    public String toUrl(String baseUrl) {
        return baseUrl + "/register?ref=" + code;
    }
}
JEOF

cat > "$PKG/domain/user/Admin.java" << 'JEOF'
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
                 boolean emailVerifie, String tokenVerif, String telephone,
                 LocalDateTime createdAt, LocalDateTime updatedAt, String niveauAcces) {
        super(id, prenom, nom, email, motDePasseHache, role, statut,
              tentatives, bloque, derniereCo, emailVerifie, tokenVerif,
              telephone, createdAt, updatedAt);
        this.niveauAcces = niveauAcces;
    }

    public String getNiveauAcces() { return niveauAcces; }
}
JEOF

cat > "$PKG/domain/user/UserDomainService.java" << 'JEOF'
// MbemNova — domain/user/UserDomainService.java
package com.mbem.mbemlevel.domain.user;

import com.mbem.mbemlevel.domain.user.valueobject.LienParrainage;

/**
 * Service domaine — règles métier qui impliquent plusieurs entités User
 * ou qui ne rentrent pas naturellement dans un seul agrégat.
 */
public class UserDomainService {

    /**
     * Génère un code de parrainage unique pour un apprenant.
     * Le use case vérifie l'unicité en base avant de persister.
     */
    public LienParrainage genererCodeParrainage() {
        return LienParrainage.generer();
    }

    /**
     * Vérifie qu'un apprenant peut parrainer (doit être CERTIFIE ou avoir fini un module).
     */
    public boolean peutParrainer(Apprenant apprenant) {
        return apprenant.getXpTotal() >= 100;  // A complété au moins un module
    }
}
JEOF

log_ok "Apprenant, Formateur, Admin, ProfilTalent, LienParrainage, UserDomainService"

# =============================================================================
# RÉSUMÉ
# =============================================================================
echo ""
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo -e "${C_BOLD}${C_GREEN}  Script 03/15 terminé avec succès              ${C_NC}"
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo ""
echo -e "  ${C_GREEN}✓${C_NC}  AggregateRoot + ValueObject + Money + Email"
echo -e "  ${C_GREEN}✓${C_NC}  7 enums (Role, Statut, ModePaiement...)"
echo -e "  ${C_GREEN}✓${C_NC}  DomainEvent interface + 11 events"
echo -e "  ${C_GREEN}✓${C_NC}  Utilisateur (agrégat complet + règles métier)"
echo -e "  ${C_GREEN}✓${C_NC}  Apprenant + Formateur + Admin"
echo -e "  ${C_GREEN}✓${C_NC}  ProfilTalent + LienParrainage + UserDomainService"
echo ""
echo -e "  ${C_BLUE}Note${C_NC} : Les domaines Cours, Paiement, Session, Certificat"
echo -e "         seront implémentés dans les scripts 10 à 12."
echo ""
echo -e "  \033[1;33m→ Prochain script : ./s04_application_ports.sh\033[0m"
echo ""
