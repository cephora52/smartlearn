package com.mbem.mbemlevel.api.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("MoratoireController — RBAC & Security Tests")
class MoratoireControllerIT {

    @Autowired
    private MockMvc mvc;

    @Test
    @DisplayName("POST /moratoires sans JWT → 401")
    void demander_sansJwt_retourne401() throws Exception {
        mvc.perform(post("/api/v1/moratoires")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("GET /moratoires sans JWT → 401")
    void obtenirTous_sansJwt_retourne401() throws Exception {
        mvc.perform(get("/api/v1/moratoires"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("PATCH /moratoires/{id}/decider sans JWT → 401")
    void decider_sansJwt_retourne401() throws Exception {
        mvc.perform(patch("/api/v1/moratoires/00000000-0000-0000-0000-000000000000/decider")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isUnauthorized());
    }
}
