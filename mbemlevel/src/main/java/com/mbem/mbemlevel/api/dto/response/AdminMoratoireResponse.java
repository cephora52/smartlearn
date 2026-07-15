package com.mbem.mbemlevel.api.dto.response;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record AdminMoratoireResponse(
    UUID id,
    UUID paiementId,
    String raison,
    LocalDate nouvelleDateSouhaitee,
    LocalDate nouvelleDateAccordee,
    String statut,
    UUID adminId,
    String justificationRefus,
    LocalDateTime dateDecision,
    LocalDateTime createdAt,
    
    // Informations de l'apprenant
    UUID apprenantId,
    String apprenantNom,
    String apprenantPrenom,
    String apprenantEmail,
    
    // Informations de la formation
    UUID coursId,
    String coursTitre
) {}
