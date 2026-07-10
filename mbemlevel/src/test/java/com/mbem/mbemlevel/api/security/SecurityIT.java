package com.mbem.mbemlevel.api.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("test")
@DisplayName("Sécurité — Tests d'intégration")
class SecurityIT {

    @Autowired private MockMvc mvc;

    @Test
    @DisplayName("Endpoint protégé sans JWT → 401 JSON (pas de redirect HTML)")
    void endpointProtege_sansJwt_retourne401Json() throws Exception {
        mvc.perform(get("/api/v1/progression"))
            .andExpect(status().isUnauthorized())
            .andExpect(content().contentType("application/json"))
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.error.code").value("UNAUTHORIZED"));
    }

    @Test
    @DisplayName("JWT invalide (signature fausse) → 401 JSON")
    void jwtInvalide_retourne401() throws Exception {
        mvc.perform(get("/api/v1/progression")
                .header("Authorization", "Bearer invalid.jwt.token"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Headers sécurité présents sur les réponses API")
    void headerSecuritePresents() throws Exception {
        mvc.perform(get("/api/v1/cours"))
            .andExpect(header().exists("X-Content-Type-Options"))
            .andExpect(header().exists("X-Frame-Options"))
            .andExpect(header().string("Cache-Control", org.hamcrest.Matchers.containsString("no-store")));
    }

    @Test
    @DisplayName("Endpoint /actuator/health → 200 public")
    void actuatorHealth_public() throws Exception {
        mvc.perform(get("/actuator/health"))
            .andExpect(status().isOk());
    }
}
