// MbemNova — domain/event/PaiementEnRetardEvent.java
// Échéance dépassée — déclenche relances automatiques J+3 J+7 J+10
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Échéance dépassée — déclenche relances automatiques J+3 J+7 J+10
 * Type  : PAIEMENT_EN_RETARD
 */
public record PaiementEnRetardEvent(UUID paiementId, UUID apprenantId, String prenom, String email, String telephone, int joursRetard, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public PaiementEnRetardEvent(UUID paiementId, UUID apprenantId, String prenom, String email, String telephone, int joursRetard) {
        this(paiementId, apprenantId, prenom, email, telephone, joursRetard, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "PAIEMENT_EN_RETARD"; }
}
