package com.mbem.mbemlevel.application.usecase;

import com.mbem.mbemlevel.application.dto.request.InscriptionCommand;
import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.application.usecase.auth.InscrireApprenantUseCase;
import com.mbem.mbemlevel.application.usecase.auth.JwtFacade;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Collections;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("InscrireApprenant — Use Case")
class InscrireApprenantUseCaseTest {

    @Mock private UtilisateurRepository    utilisateurRepo;
    @Mock private PasswordEncoder          passwordEncoder;
    @Mock private JwtFacade                jwtFacade;
    @Mock private AuditLogRepository       auditRepo;
    @Mock private ApplicationEventPublisher eventPublisher;
    @Mock private EmailPort                emailPort;

    @InjectMocks
    private InscrireApprenantUseCase useCase;

    @Test
    @DisplayName("executer() crée l'apprenant et retourne les tokens")
    void executer_creationEtRetourTokens() {
        // Arrange
        when(utilisateurRepo.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$12$hashed");
        Utilisateur savedUser = Utilisateur.creer("Alice", "Test", "alice@test.com", "$2a$12$hashed", com.mbem.mbemlevel.domain.shared.enums.Role.APPRENANT, "0606060606");
        when(utilisateurRepo.save(any())).thenReturn(savedUser);
        when(jwtFacade.genererToken(anyString(), anyString(), anyString())).thenReturn("mock.accessToken");
        when(jwtFacade.genererRefreshToken(any(), anyInt(), anyString(), anyString())).thenReturn("mock.refreshToken");

        // Act
        AuthResultDto result = useCase.executer(
            new InscriptionCommand("Test", "Alice", "alice@test.com", "0606060606", "Password1!", "APPRENANT", "127.0.0.1", "Test"));

        // Assert
        assertThat(result.accessToken()).isEqualTo("mock.accessToken");
        assertThat(result.refreshToken()).isEqualTo("mock.refreshToken");
        assertThat(result.prenom()).isEqualTo("Alice");
        verify(utilisateurRepo).save(any(Utilisateur.class));
        verify(eventPublisher, atLeastOnce()).publishEvent(any(Object.class));
    }

    @Test
    @DisplayName("executer() email déjà utilisé → IllegalStateException")
    void executer_emailExistant_lanceException() {
        when(utilisateurRepo.existsByEmail("alice@test.com")).thenReturn(true);
        assertThatThrownBy(() ->
            useCase.executer(
                new InscriptionCommand("Test", "Alice", "alice@test.com", "0606060606", "Password1!", "APPRENANT", "127.0.0.1", "")))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("EMAIL_ALREADY_EXISTS");
        verify(utilisateurRepo, never()).save(any());
    }

    @Test
    @DisplayName("executer() hache le mot de passe — jamais stocké en clair")
    void executer_hacheLeMotDePasse() {
        when(utilisateurRepo.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode("Password1!")).thenReturn("$2a$12$hashed");
        Utilisateur u = Utilisateur.creer("Alice", "Test", "alice@test.com", "$2a$12$hashed", com.mbem.mbemlevel.domain.shared.enums.Role.APPRENANT, "0606060606");
        when(utilisateurRepo.save(any())).thenReturn(u);

        useCase.executer(
            new InscriptionCommand("Test", "Alice", "alice@test.com", "0606060606", "Password1!", "APPRENANT", "127.0.0.1", ""));

        // Vérifier que le mot de passe encodé a été utilisé
        verify(passwordEncoder).encode("Password1!");
    }
}
