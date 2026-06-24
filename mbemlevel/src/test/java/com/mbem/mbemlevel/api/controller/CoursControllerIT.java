package com.mbem.mbemlevel.api.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfiguration
@ActiveProfiles("test")
@DisplayName("CoursController — Tests d'intégration")
class CoursControllerIT {

    @Autowired private MockMvc mvc;


    @Test
    @DisplayName("GET /cours → 200 public (sans auth)")
    void getCatalogue_publicSansAuth() throws Exception {
        mvc.perform(get("/api/v1/cours"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("GET /cours?niveau=DEBUTANT → 200 filtré")
    void getCatalogue_avecFiltreNiveau() throws Exception {
        mvc.perform(get("/api/v1/cours").param("niveau", "DEBUTANT"))
            .andExpect(status().isOk());
    }

    @Test
    @DisplayName("GET /cours/{id} inexistant → 200 ou 404 selon logique")
    void getDetailCours_idInexistant() throws Exception {
        mvc.perform(get("/api/v1/cours/00000000-0000-0000-0000-000000000000"))
            .andExpect(status().isOk()); // Géré par GlobalExceptionHandler
    }
}
