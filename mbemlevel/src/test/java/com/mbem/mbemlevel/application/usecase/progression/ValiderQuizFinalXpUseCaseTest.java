package com.mbem.mbemlevel.application.usecase.progression;

import com.mbem.mbemlevel.application.port.out.ProgressionRepository;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.XpHistoriqueJpaRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ValiderQuizFinalXp — Use Case")
class ValiderQuizFinalXpUseCaseTest {

    @Mock private ProgressionRepository progressionRepo;
    @Mock private UtilisateurJpaRepository utilisateurRepo;
    @Mock private XpHistoriqueJpaRepository xpHistoriqueRepo;

    @InjectMocks private ValiderQuizFinalXpUseCase useCase;

    @Test
    @DisplayName("Formation terminée à 100% et quiz non fait → attribue 50 XP et marque comme fait")
    void formationTerminee_attribueXp() {
        UUID aid = UUID.randomUUID(), cid = UUID.randomUUID(), pid = UUID.randomUUID();

        Progression progression = new Progression(pid, aid, cid, 100.0, true, 200, LocalDateTime.now(), null, 0.3, LocalDateTime.now(), LocalDateTime.now());
        progression.setFinalQuizDone(false);

        when(progressionRepo.findByApprenantIdAndCoursId(aid, cid)).thenReturn(Optional.of(progression));
        when(progressionRepo.save(any(Progression.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Progression result = useCase.executer(aid, cid);

        assertThat(result.isFinalQuizDone()).isTrue();
        assertThat(result.getXpGagne()).isEqualTo(250); // 200 + 50
        verify(xpHistoriqueRepo, times(1)).save(any());
        verify(utilisateurRepo, times(1)).findById(aid);
    }

    @Test
    @DisplayName("Formation non terminée à 100% → lance une exception")
    void formationNonTerminee_lanceException() {
        UUID aid = UUID.randomUUID(), cid = UUID.randomUUID(), pid = UUID.randomUUID();

        Progression progression = new Progression(pid, aid, cid, 50.0, true, 50, LocalDateTime.now(), null, 0.3, LocalDateTime.now(), LocalDateTime.now());

        when(progressionRepo.findByApprenantIdAndCoursId(aid, cid)).thenReturn(Optional.of(progression));

        assertThatThrownBy(() -> useCase.executer(aid, cid))
            .isInstanceOf(RuntimeException.class)
            .hasMessageContaining("La formation doit être terminée à 100%");
    }
}
