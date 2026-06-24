// MbemNova — domain/event/ParrainageActiveEvent.java
// Filleul a complété son premier module — active la récompense parrain
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Filleul a complété son premier module — active la récompense parrain
 * Type  : PARRAINAGE_ACTIVE
 */
public record ParrainageActiveEvent(UUID parrainId, UUID filleulId, String emailParrain, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public ParrainageActiveEvent(UUID parrainId, UUID filleulId, String emailParrain) {
        this(parrainId, filleulId, emailParrain, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "PARRAINAGE_ACTIVE"; }
}
