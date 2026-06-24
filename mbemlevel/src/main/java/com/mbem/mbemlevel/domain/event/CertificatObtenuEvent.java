// MbemNova — domain/event/CertificatObtenuEvent.java
// Certificat généré — email + WhatsApp + mise à jour profil talent
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Certificat généré — email + WhatsApp + mise à jour profil talent
 * Type  : CERTIFICAT_OBTENU
 */
public record CertificatObtenuEvent(UUID certificatId, UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours, String codeVerif, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public CertificatObtenuEvent(UUID certificatId, UUID apprenantId, UUID coursId, String prenom, String email, String telephone, String nomCours, String codeVerif) {
        this(certificatId, apprenantId, coursId, prenom, email, telephone, nomCours, codeVerif, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "CERTIFICAT_OBTENU"; }
}
