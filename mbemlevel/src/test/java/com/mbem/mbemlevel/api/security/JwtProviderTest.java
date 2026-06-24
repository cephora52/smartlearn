package com.mbem.mbemlevel.api.security;

import com.mbem.mbemlevel.infrastructure.security.token.JwtTokenProvider;
import com.nimbusds.jwt.JWTClaimsSet;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

@DisplayName("JwtTokenProvider — Tests unitaires")
class JwtProviderTest {

    private JwtTokenProvider provider;
    private static final String SECRET =
        "mbemnova-test-secret-key-min-32-characters-long-256bits";

    @BeforeEach
    void setUp() {
        provider = new JwtTokenProvider(SECRET, 3600_000L); // 1h
    }

    @Test
    @DisplayName("genererToken() crée un JWT valide")
    void genererToken_jwtValide() {
        String token = provider.genererToken("user-id", "user@t.com", "APPRENANT");
        assertThat(token).isNotBlank().contains(".");
        assertThat(provider.estValide(token)).isTrue();
    }

    @Test
    @DisplayName("validerEtExtraireClaims() retourne le bon userId")
    void valider_retourneUserId() throws Exception {
        String token = provider.genererToken("abc-123", "u@t.com", "FORMATEUR");
        JWTClaimsSet claims = provider.validerEtExtraireClaims(token);
        assertThat(claims.getSubject()).isEqualTo("abc-123");
        assertThat(claims.getClaim("role")).isEqualTo("FORMATEUR");
        assertThat(claims.getClaim("email")).isEqualTo("u@t.com");
    }

    @Test
    @DisplayName("extraireJti() retourne un UUID non null")
    void extraireJti_retourneUUID() {
        String token = provider.genererToken("x", "x@t.com", "APPRENANT");
        assertThat(provider.extraireJti(token)).isNotBlank();
    }

    @Test
    @DisplayName("Token modifié → estValide() retourne false")
    void tokenModifie_invalide() {
        String token = provider.genererToken("x", "x@t.com", "APPRENANT");
        String tampered = token.substring(0, token.length() - 5) + "xxxxx";
        assertThat(provider.estValide(tampered)).isFalse();
    }

    @Test
    @DisplayName("Secret trop court → IllegalStateException au démarrage")
    void secretTropCourt_lanceException() {
        assertThatThrownBy(() -> new JwtTokenProvider("court", 3600_000L))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("JWT_SECRET");
    }
}
