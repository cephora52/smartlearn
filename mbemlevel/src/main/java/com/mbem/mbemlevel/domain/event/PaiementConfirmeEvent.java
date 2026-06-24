// MbemNova — domain/event/PaiementConfirmeEvent.java
// Paiement confirmé — active accès complet + génère facture PDF
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Paiement confirmé — active accès complet + génère facture PDF
 * Type  : PAIEMENT_CONFIRME
 */
public record PaiementConfirmeEvent(UUID paiementId, UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public PaiementConfirmeEvent(UUID paiementId, UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours) {
        this(paiementId, apprenantId, coursId, prenom, email, telephone, nomCours, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "PAIEMENT_CONFIRME"; }
}
