// MbemNova — domain/event/CompteReactiveEvent.java
// Compte réactivé après régularisation du paiement
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Compte réactivé après régularisation du paiement
 * Type  : COMPTE_REACTIVE
 */
public record CompteReactiveEvent(UUID apprenantId, String prenom, String email, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public CompteReactiveEvent(UUID apprenantId, String prenom, String email) {
        this(apprenantId, prenom, email, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "COMPTE_REACTIVE"; }
}
