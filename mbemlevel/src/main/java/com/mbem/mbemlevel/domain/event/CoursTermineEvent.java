// MbemNova — domain/event/CoursTermineEvent.java
// Toutes leçons et QCM validés — déclenche génération du certificat
package com.mbem.mbemlevel.domain.event;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Event : Toutes leçons et QCM validés — déclenche génération du certificat
 * Type  : COURS_TERMINE
 */
public record CoursTermineEvent(UUID apprenantId, UUID coursId, String prenom, String email, String nomCours, UUID eventId, LocalDateTime occurredAt)
    implements DomainEvent {

    /** Constructeur pratique — génère automatiquement eventId et occurredAt. */
    public CoursTermineEvent(UUID apprenantId, UUID coursId, String prenom, String email, String nomCours) {
        this(apprenantId, coursId, prenom, email, nomCours, UUID.randomUUID(), LocalDateTime.now());
    }

    @Override public UUID getEventId()             { return eventId; }
    @Override public LocalDateTime getOccurredAt() { return occurredAt; }
    @Override public String getEventType()         { return "COURS_TERMINE"; }
}
