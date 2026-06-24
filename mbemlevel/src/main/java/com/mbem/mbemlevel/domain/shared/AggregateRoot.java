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
