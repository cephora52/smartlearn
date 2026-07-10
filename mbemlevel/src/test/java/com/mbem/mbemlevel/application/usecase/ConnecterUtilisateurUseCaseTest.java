package com.mbem.mbemlevel.application.usecase;

import com.mbem.mbemlevel.application.dto.request.ConnexionCommand;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.application.usecase.auth.ConnecterUtilisateurUseCase;
import com.mbem.mbemlevel.application.usecase.auth.JwtFacade;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ConnecterUtilisateur — Use Case")
class ConnecterUtilisateurUseCaseTest {

    @Mock private UtilisateurRepository    utilisateurRepo;
    @Mock private PasswordEncoder          passwordEncoder;
    @Mock private JwtFacade                jwtFacade;
    @Mock private AuditLogRepository       auditRepo;

    @InjectMocks
    private ConnecterUtilisateurUseCase useCase;

    @Test
    @DisplayName("Email inexistant → SecurityException avec message générique")
    void emailInexistant_messageGenerique() {
        when(utilisateurRepo.findByEmail("inconnu@test.com")).thenReturn(Optional.empty());
        assertThatThrownBy(() ->
            useCase.executer(new ConnexionCommand("inconnu@test.com", "pass", false, "ip", "ua")))
            .isInstanceOf(SecurityException.class)
            .hasMessage("INVALID_CREDENTIALS"); // Jamais "email introuvable"
    }

    @Test
    @DisplayName("Mot de passe incorrect → SecurityException + incrément tentatives")
    void motDePasseIncorrect_incrementeTentatives() {
        Utilisateur u = Utilisateur.creer("Bob", "bob@test.com", "$2a$12$hash");
        when(utilisateurRepo.findByEmail("bob@test.com")).thenReturn(Optional.of(u));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(false);

        assertThatThrownBy(() ->
            useCase.executer(new ConnexionCommand("bob@test.com", "mauvais", false, "ip", "ua")))
            .isInstanceOf(SecurityException.class);

        assertThat(u.getTentativesEchouees()).isEqualTo(1);
        verify(utilisateurRepo).save(u);
    }

    @Test
    @DisplayName("Connexion réussie → tokens retournés")
    void connexionReussie_retourneTokens() {
        Utilisateur u = Utilisateur.creer("Bob", "bob@test.com", "$2a$12$hash");
        u.verifierEmail();
        when(utilisateurRepo.findByEmail("bob@test.com")).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("motdepasse", "$2a$12$hash")).thenReturn(true);
        when(utilisateurRepo.save(any())).thenReturn(u);
        when(jwtFacade.genererToken(any(),any(),any())).thenReturn("access.token");
        when(jwtFacade.genererRefreshToken(any(),anyInt(),any(),any())).thenReturn("refresh.token");

        var result = useCase.executer(
            new ConnexionCommand("bob@test.com", "motdepasse", false, "127.0.0.1", "ua"));

        assertThat(result.accessToken()).isEqualTo("access.token");
        assertThat(u.getTentativesEchouees()).isZero(); // Réinitialisé
    }
}
