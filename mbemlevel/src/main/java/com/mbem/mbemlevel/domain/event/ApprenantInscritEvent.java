// MbemNova — domain/event/ApprenantInscritEvent.java
// Nouvel apprenant inscrit — déclenche email bienvenue + rappel 48h
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Nouvel apprenant inscrit — déclenche email bienvenue + rappel 48h
 * Type  : APPRENANT_INSCRIT
 */
public record ApprenantInscritEvent(UUID apprenantId, String prenom, String email, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public ApprenantInscritEvent(UUID apprenantId, String prenom, String email) {
        this(apprenantId, prenom, email, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "APPRENANT_INSCRIT"; }
}
