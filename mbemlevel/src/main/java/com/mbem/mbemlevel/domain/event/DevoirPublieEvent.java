// MbemNova — domain/event/DevoirPublieEvent.java
// Formateur a publié un devoir — notifie les apprenants
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Formateur a publié un devoir — notifie les apprenants
 * Type  : DEVOIR_PUBLIE
 */
public record DevoirPublieEvent(UUID devoirId, UUID sessionId, String nomDevoir, String dateRemise, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public DevoirPublieEvent(UUID devoirId, UUID sessionId, String nomDevoir, String dateRemise) {
        this(devoirId, sessionId, nomDevoir, dateRemise, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "DEVOIR_PUBLIE"; }
}
