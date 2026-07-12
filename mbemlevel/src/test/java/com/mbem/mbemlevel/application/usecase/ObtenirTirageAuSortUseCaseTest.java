package com.mbem.mbemlevel.application.usecase;

import com.mbem.mbemlevel.application.port.out.TirageAuSortRepository;
import com.mbem.mbemlevel.application.usecase.gamification.ObtenirTirageAuSortUseCase;
import com.mbem.mbemlevel.domain.gamification.TirageAuSort;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("ObtenirTirageAuSort — Use Case")
class ObtenirTirageAuSortUseCaseTest {

    @Mock
    private TirageAuSortRepository tirageRepository;

    @InjectMocks
    private ObtenirTirageAuSortUseCase useCase;

    @Test
    @DisplayName("Aucun tirage en base → retourne empty")
    void aucunTirageEnBase_retourneEmpty() {
        when(tirageRepository.findLatest()).thenReturn(Optional.empty());

        var result = useCase.executer();

        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("Tirage présent avec gagnant → retourne DrawResponse formatée")
    void tiragePresent_retourneDrawResponse() {
        UUID tirageId = UUID.randomUUID();
        UUID gagnantId = UUID.randomUUID();
        TirageAuSort tirage = new TirageAuSort(
            tirageId,
            LocalDate.of(2026, 7, 1),
            gagnantId,
            15,
            "Cours de Dev",
            LocalDateTime.now(),
            LocalDateTime.now()
        );

        when(tirageRepository.findLatest()).thenReturn(Optional.of(tirage));
        when(tirageRepository.findGagnantPrenom(tirageId)).thenReturn(Optional.of("Alice"));

        var result = useCase.executer();

        assertThat(result).isPresent();
        var resp = result.get();
        assertThat(resp.id()).isEqualTo(tirageId.toString());
        assertThat(resp.dateDrawFormatee()).isEqualTo("1er juillet 2026");
        assertThat(resp.formationGagnanteTitre()).isEqualTo("Cours de Dev");
        assertThat(resp.gagnantPrenom()).isEqualTo("Alice");
        assertThat(resp.nbTicketsVendus()).isEqualTo(15);
        assertThat(resp.statut()).isEqualTo("GAGNANT_SELECTIONNE");
    }
}
