package com.mbem.mbemlevel.application.usecase.ai;

import com.mbem.mbemlevel.application.port.out.GeminiPort;
import com.mbem.mbemlevel.domain.cours.TypeBloc;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("GenererResumeLecon — Use Case")
class GenererResumeLeconUseCaseTest {

    @Mock private LeconJpaRepository leconRepo;
    @Mock private BlocContenuJpaRepository blocRepo;
    @Mock private CoursJpaRepository coursRepo;
    @Mock private UtilisateurJpaRepository utilisateurRepo;
    @Mock private ProgressionJpaRepository progressionRepo;
    @Mock private PaiementJpaRepository paiementRepo;
    @Mock private MoratoireJpaRepository moratoireRepo;
    @Mock private GeminiPort geminiPort;

    @InjectMocks private GenererResumeLeconUseCase useCase;

    @Test
    @DisplayName("Leçon gratuite accessible → génère le résumé de la leçon")
    void leconGratuiteAccessible_genereResume() {
        UUID uid = UUID.randomUUID(), cid = UUID.randomUUID(), lid = UUID.randomUUID();

        LeconJpaEntity lecon = LeconJpaEntity.builder()
            .id(lid)
            .coursId(cid)
            .titre("Intro")
            .estPreview(true)
            .build();

        CoursJpaEntity cours = CoursJpaEntity.builder()
            .id(cid)
            .prixFcfa(10000)
            .seuilPaiement(BigDecimal.valueOf(0.3))
            .build();

        BlocContenuJpaEntity bloc = BlocContenuJpaEntity.builder()
            .typeBloc(TypeBloc.TEXTE_HTML)
            .contenuHtml("<p>Contenu leçon</p>")
            .build();

        when(leconRepo.findById(lid)).thenReturn(Optional.of(lecon));
        when(coursRepo.findById(cid)).thenReturn(Optional.of(cours));
        when(leconRepo.findByCoursIdOrderByOrdreAsc(cid)).thenReturn(List.of(lecon));
        when(blocRepo.findByLeconIdOrderByOrdreAsc(lid)).thenReturn(List.of(bloc));
        when(geminiPort.generateResponse(anyString())).thenReturn("Résumé de l'IA.");

        String result = useCase.executer(lid, uid);

        assertThat(result).isEqualTo("Résumé de l'IA.");
    }

    @Test
    @DisplayName("Leçon payante verrouillée → lance une exception de droits d'accès")
    void leconPayanteVerrouillee_lanceException() {
        UUID uid = UUID.randomUUID(), cid = UUID.randomUUID(), lid = UUID.randomUUID();

        LeconJpaEntity lecon = LeconJpaEntity.builder()
            .id(lid)
            .coursId(cid)
            .titre("Module 2")
            .estPreview(false)
            .build();

        CoursJpaEntity cours = CoursJpaEntity.builder()
            .id(cid)
            .prixFcfa(10000)
            .seuilPaiement(BigDecimal.valueOf(0.3))
            .build();

        when(leconRepo.findById(lid)).thenReturn(Optional.of(lecon));
        when(coursRepo.findById(cid)).thenReturn(Optional.of(cours));
        // two lessons, first is free (index 0), second is locked (index 1)
        LeconJpaEntity freeLecon = LeconJpaEntity.builder().id(UUID.randomUUID()).build();
        when(leconRepo.findByCoursIdOrderByOrdreAsc(cid)).thenReturn(List.of(freeLecon, lecon));

        assertThatThrownBy(() -> useCase.executer(lid, uid))
            .isInstanceOf(com.mbem.mbemlevel.api.exception.AccesInterditException.class);
    }
}
