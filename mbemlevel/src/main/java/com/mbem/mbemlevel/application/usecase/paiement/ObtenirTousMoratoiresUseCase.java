package com.mbem.mbemlevel.application.usecase.paiement;

import com.mbem.mbemlevel.api.dto.response.AdminMoratoireResponse;
import com.mbem.mbemlevel.application.port.out.MoratoireRepository;
import com.mbem.mbemlevel.application.port.out.PaiementRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ObtenirTousMoratoiresUseCase {

    private final MoratoireRepository moratoireRepo;
    private final PaiementRepository paiementRepo;
    private final UtilisateurJpaRepository utilisateurRepo;
    private final CoursJpaRepository coursRepo;

    @Transactional(readOnly = true)
    public List<AdminMoratoireResponse> executer() {
        return moratoireRepo.findAll().stream()
            .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()))
            .map(m -> {
                var paiementOpt = paiementRepo.findById(m.getPaiementId());
                UUID apprenantId = null;
                String nom = "";
                String prenom = "";
                String email = "";
                UUID coursId = null;
                String coursTitre = "";

                if (paiementOpt.isPresent()) {
                    var p = paiementOpt.get();
                    apprenantId = p.getApprenantId();
                    coursId = p.getCoursId();

                    var uOpt = utilisateurRepo.findById(apprenantId);
                    if (uOpt.isPresent()) {
                        nom = uOpt.get().getNom() != null ? uOpt.get().getNom() : "";
                        prenom = uOpt.get().getPrenom() != null ? uOpt.get().getPrenom() : "";
                        email = uOpt.get().getEmail() != null ? uOpt.get().getEmail() : "";
                    }

                    var cOpt = coursRepo.findById(coursId);
                    if (cOpt.isPresent()) {
                        coursTitre = cOpt.get().getTitre();
                    }
                }

                return new AdminMoratoireResponse(
                    m.getId(),
                    m.getPaiementId(),
                    m.getRaison(),
                    m.getNouvelledateSouhaitee(),
                    m.getNouvelledateAccordee(),
                    m.getStatut(),
                    m.getAdminId(),
                    m.getJustificationRefus(),
                    m.getDateDecision(),
                    m.getCreatedAt(),
                    apprenantId,
                    nom,
                    prenom,
                    email,
                    coursId,
                    coursTitre
                );
            })
            .collect(Collectors.toList());
    }
}
