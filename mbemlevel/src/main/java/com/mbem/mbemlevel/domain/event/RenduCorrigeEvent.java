// MbemNova — domain/event/RenduCorrigeEvent.java
// Formateur a noté le rendu — notifie l'apprenant
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Formateur a noté le rendu — notifie l'apprenant
 * Type  : RENDU_CORRIGE
 */
public record RenduCorrigeEvent(UUID renduId, UUID apprenantId, String prenom, String email, int note, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public RenduCorrigeEvent(UUID renduId, UUID apprenantId, String prenom, String email, int note) {
        this(renduId, apprenantId, prenom, email, note, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "RENDU_CORRIGE"; }
}
