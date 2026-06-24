// MbemNova — domain/event/SeuilPaiementAtteintEvent.java
// Seuil de conversion atteint — déclenche email nurturing + WhatsApp J+1
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Seuil de conversion atteint — déclenche email nurturing + WhatsApp J+1
 * Type  : SEUIL_PAIEMENT_ATTEINT
 */
public record SeuilPaiementAtteintEvent(UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours, double pctActuel, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public SeuilPaiementAtteintEvent(UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours, double pctActuel) {
        this(apprenantId, coursId, prenom, email, telephone, nomCours, pctActuel, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "SEUIL_PAIEMENT_ATTEINT"; }
}
