package com.mbem.mbemlevel.application.usecase.ai;

import com.mbem.mbemlevel.application.port.out.GeminiPort;
import com.mbem.mbemlevel.domain.cours.TypeBloc;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GenererResumeLeconUseCase {

    private final LeconJpaRepository leconRepo;
    private final BlocContenuJpaRepository blocRepo;
    private final CoursJpaRepository coursRepo;
    private final UtilisateurJpaRepository utilisateurRepo;
    private final ProgressionJpaRepository progressionRepo;
    private final PaiementJpaRepository paiementRepo;
    private final MoratoireJpaRepository moratoireRepo;
    private final GeminiPort geminiPort;

    @Transactional(readOnly = true)
    public String executer(UUID leconId, UUID apprenantId) {
        // 1. Charger la leçon et le cours
        LeconJpaEntity lecon = leconRepo.findById(leconId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:LECON:" + leconId));

        UUID coursId = lecon.getCoursId();
        CoursJpaEntity cours = coursRepo.findById(coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:COURS:" + coursId));

        // 2. Vérifier l'accessibilité de la leçon (similaire à GetLeconDetailUseCase)
        boolean isFormateur = apprenantId != null && apprenantId.equals(cours.getFormateurId());
        boolean isAdmin = false;
        if (apprenantId != null) {
            isAdmin = utilisateurRepo.findById(apprenantId)
                .map(u -> u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.ADMIN
                       || u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.SUPER_ADMIN)
                .orElse(false);
        }

        boolean aMoratoireApprouve = false;
        if (apprenantId != null) {
            var paiementOpt = paiementRepo.findByApprenantIdAndCoursId(apprenantId, coursId);
            if (paiementOpt.isPresent()) {
                aMoratoireApprouve = moratoireRepo.existsByPaiementIdAndStatut(paiementOpt.get().getId(), "APPROUVE")
                                  || moratoireRepo.existsByPaiementIdAndStatut(paiementOpt.get().getId(), "ACCORDE");
            }
        }

        boolean estPaye = (cours.getPrixFcfa() == 0)
            || (apprenantId != null && progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
                .map(ProgressionJpaEntity::isEstPaye).orElse(false))
            || isFormateur || isAdmin;

        List<LeconJpaEntity> lecons = leconRepo.findByCoursIdOrderByOrdreAsc(coursId);
        int totalLecons = lecons.size();
        double seuilVal = cours.getSeuilPaiement().doubleValue();
        int maxLeconsGratuites = (int) Math.ceil(totalLecons * seuilVal);

        int leconIndex = -1;
        for (int i = 0; i < totalLecons; i++) {
            if (lecons.get(i).getId().equals(leconId)) {
                leconIndex = i;
                break;
            }
        }

        boolean estDansSeuilGratuit = (leconIndex >= 0 && leconIndex < maxLeconsGratuites);
        boolean accessible = lecon.isEstPreview() || estDansSeuilGratuit || estPaye || aMoratoireApprouve;

        if (!accessible) {
            throw new com.mbem.mbemlevel.api.exception.AccesInterditException("Cette leçon est verrouillée. Veuillez payer ou demander un moratoire.");
        }

        // 3. Compiler le contenu textuel de la leçon
        List<BlocContenuJpaEntity> blocs = blocRepo.findByLeconIdOrderByOrdreAsc(leconId);
        StringBuilder textBuilder = new StringBuilder();

        for (var b : blocs) {
            if (b.getTypeBloc() == TypeBloc.TEXTE_HTML && b.getContenuHtml() != null) {
                textBuilder.append(b.getContenuHtml()).append("\n");
            } else if (b.getTypeBloc() == TypeBloc.CODE && b.getCodeSource() != null) {
                textBuilder.append("Exemple de Code (").append(b.getLangageCode() != null ? b.getLangageCode() : "").append(") :\n```")
                    .append(b.getLangageCode() != null ? b.getLangageCode() : "").append("\n")
                    .append(b.getCodeSource()).append("\n```\n");
            } else if (b.getTypeBloc() == TypeBloc.CALLOUT && b.getTexteCallout() != null) {
                textBuilder.append("> ").append(b.getTexteCallout()).append("\n");
            }
        }

        String fullContent = textBuilder.toString().strip();
        if (fullContent.isBlank()) {
            fullContent = "Titre de la leçon : " + lecon.getTitre() + "\nDescription : " + lecon.getDescriptionCourte();
        }

        // 4. Générer le prompt pour l'IA
        String prompt = "Tu es un assistant pédagogique virtuel pour la plateforme MbemNova.\n"
            + "Génère un résumé clair, synthétique, structuré et engageant de la leçon suivante.\n"
            + "Le résumé doit impérativement et automatiquement être beaucoup plus court que la leçon elle-même (maximum 20% à 30% de la longueur de la leçon, ou au maximum 200-250 mots).\n"
            + "Utilise du format Markdown (titres, listes à puces, gras, etc.) pour rendre le résumé très agréable à lire.\n"
            + "Fais des phrases courtes et mets en avant les points clés à retenir.\n"
            + "Mets un titre au format Markdown: ### Résumé de la leçon\n"
            + "Voici le contenu de la leçon :\n\n"
            + fullContent;

        // 5. Appeler l'API Gemini
        return geminiPort.generateResponse(prompt);
    }
}
