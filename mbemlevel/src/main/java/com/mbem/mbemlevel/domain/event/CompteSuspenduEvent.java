// MbemNova — domain/event/CompteSuspenduEvent.java
// Compte suspendu J+10 — email suspension + notification admin
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Compte suspendu J+10 — email suspension + notification admin
 * Type  : COMPTE_SUSPENDU
 */
public record CompteSuspenduEvent(UUID apprenantId, String prenom, String email, String messagePersonnalise, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public CompteSuspenduEvent(UUID apprenantId, String prenom, String email, String messagePersonnalise) {
        this(apprenantId, prenom, email, messagePersonnalise, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "COMPTE_SUSPENDU"; }
}
