package com.mbem.mbemlevel.application.usecase;

import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.application.usecase.talent.GenererCertificatUseCase;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import com.mbem.mbemlevel.domain.certificat.CertificatDomainService;
import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("GenererCertificat — Use Case")
class GenererCertificatUseCaseTest {

    @Mock private CertificatRepository   certRepo;
    @Mock private ProgressionRepository  progressionRepo;
    @Mock private UtilisateurRepository  utilisateurRepo;
    @Mock private CoursRepository        coursRepo;
    @Mock private AuditLogRepository     auditRepo;
    @Mock private ApplicationEventPublisher publisher;
    @Mock private CertificatDomainService   domainService;

    @InjectMocks private GenererCertificatUseCase useCase;

    @Test
    @DisplayName("Conditions non remplies (pas payé) → RuntimeException")
    void conditionsNonRemplies_lanceException() {
        UUID uid = UUID.randomUUID(), cid = UUID.randomUUID();
        Progression prog = Progression.commencer(uid, cid, 0.30);
        Cours mockCours = mock(Cours.class);
        when(mockCours.getPrixFcfa()).thenReturn(1000L);
        when(coursRepo.findById(cid)).thenReturn(Optional.of(mockCours));
        when(certRepo.findByApprenantAndCours(uid, cid)).thenReturn(Optional.empty());
        when(progressionRepo.findByApprenantIdAndCoursId(uid, cid)).thenReturn(Optional.of(prog));
        when(domainService.peutObtenirCertificat(prog)).thenReturn(false);

        assertThatThrownBy(() -> useCase.executer(uid, cid))
            .isInstanceOf(RuntimeException.class)
            .hasMessage("CERTIFICATE_CONDITIONS_NOT_MET");
    }

    @Test
    @DisplayName("Certificat déjà généré → retourne l'existant (idempotent)")
    void certificatExistant_retourneExistant() {
        UUID uid = UUID.randomUUID(), cid = UUID.randomUUID();
        Certificat existant = Certificat.emettre(uid, cid, "Alice", "a@t.com", null, "Cours Java");
        existant.clearDomainEvents();
        when(certRepo.findByApprenantAndCours(uid, cid)).thenReturn(Optional.of(existant));

        Certificat result = useCase.executer(uid, cid);
        assertThat(result).isSameAs(existant);
        verify(certRepo, never()).save(any());
    }
}
