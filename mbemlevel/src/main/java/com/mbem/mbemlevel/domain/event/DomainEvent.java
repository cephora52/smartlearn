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
