package com.mbem.mbemlevel.application.usecase.session;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.session.Rendu;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S23 — Formateur corrige un rendu → note + commentaire → event → notification.
 */
@Service @RequiredArgsConstructor @Slf4j
public class CorrigerRenduUseCase {
    private final SessionRepository    sessionRepo;
    private final UtilisateurRepository utilisateurRepo;
    private final ApplicationEventPublisher publisher;

    @Transactional
    public Rendu executer(UUID renduId, int note, String commentaire) {
        Rendu rendu = sessionRepo.findRendusParDevoir(renduId).stream()
            .filter(r -> r.getId().equals(renduId)).findFirst()
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        Utilisateur apprenant = utilisateurRepo.findById(rendu.getApprenantId())
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
        rendu.corriger(note, commentaire, apprenant.getPrenom(), apprenant.getEmail());
        Rendu saved = sessionRepo.saveRendu(rendu);
        saved.getDomainEvents().forEach(publisher::publishEvent);
        saved.clearDomainEvents();
        return saved;
    }
}
