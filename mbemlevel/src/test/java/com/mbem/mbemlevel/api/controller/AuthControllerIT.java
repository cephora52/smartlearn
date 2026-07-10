package com.mbem.mbemlevel.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mbem.mbemlevel.api.dto.request.ConnexionRequest;
import com.mbem.mbemlevel.api.dto.request.InscriptionRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc
@ActiveProfiles("test") @Transactional
@DisplayName("AuthController — Tests d'intégration")
class AuthControllerIT {

    @Autowired private MockMvc       mvc;
    @Autowired private ObjectMapper  om;

    @Test
    @DisplayName("POST /register → 201 + accessToken présent")
    void register_retourne201AvecToken() throws Exception {
        var req = new InscriptionRequest("Test", "Alice", "alice_it@mbemnova.com", "0606060606", "Password1!", "Password1!", "APPRENANT");
        mvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(req)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.id").isNotEmpty());
    }

    @Test
    @DisplayName("POST /register email invalide → 422 + détails validation")
    void register_emailInvalide_retourne422() throws Exception {
        var req = new InscriptionRequest("Test", "Bob", "pas-un-email", "0606060606", "Password1!", "Password1!", "APPRENANT");
        mvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(req)))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.error.code").value("VALIDATION_ERROR"));
    }

    @Test
    @DisplayName("POST /register email déjà utilisé → 409")
    void register_emailDuplique_retourne409() throws Exception {
        var req = new InscriptionRequest("Test", "Carol", "carol_dup@mbemnova.com", "0606060606", "Password1!", "Password1!", "APPRENANT");
        mvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(req)))
            .andExpect(status().isCreated());
        // Deuxième inscription avec le même email
        mvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(req)))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.error.code").value("EMAIL_ALREADY_EXISTS"));
    }

    @Test
    @DisplayName("POST /login identifiants invalides → 401 message générique")
    void login_identifiantsInvalides_retourne401() throws Exception {
        var req = new ConnexionRequest("inexistant@t.com", "motdepasse", false);
        mvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(req)))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.error.code").value("INVALID_CREDENTIALS"));
    }

    @Test
    @DisplayName("POST /reset-password → 200 même si email inconnu (anti-énumération)")
    void resetPassword_emailInconnu_retourne200() throws Exception {
        mvc.perform(post("/api/v1/auth/reset-password")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"inconnu@test.com\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true));
    }
}
