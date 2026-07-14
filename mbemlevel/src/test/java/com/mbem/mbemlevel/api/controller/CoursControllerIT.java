package com.mbem.mbemlevel.api.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import java.util.UUID;

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
    @Autowired private com.mbem.mbemlevel.application.usecase.cours.CreerCoursCompletUseCase creerCoursCompletUC;
    @Autowired private com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository coursJpaRepo;
    @Autowired private com.mbem.mbemlevel.infrastructure.persistence.repository.LeconJpaRepository leconRepo;

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

    @Test
    @DisplayName("CreerCoursCompletUseCase should persist course and lessons correctly")
    void testCreerCoursComplet() {
        UUID formateurId = UUID.randomUUID();
        // Insert mock formateur in database first to satisfy foreign key constraints if any
        // utilisateurs table is audited, let's create a minimal user
        var userRepo = org.springframework.context.ApplicationContext.class.cast(null); // not needed if it's mock
        
        var req = new com.mbem.mbemlevel.api.dto.request.CreerCoursCompletRequest(
            "Test Course Title",
            "Short desc",
            "Desc",
            "Long desc",
            com.mbem.mbemlevel.domain.shared.enums.NiveauCours.DEBUTANT,
            UUID.randomUUID(), // categorieId
            60, // duration
            "banner.png",
            0.30,
            10000L,
            java.util.List.of("Objectif 1"),
            "Prerequis",
            "Public",
            java.util.List.of(
                new com.mbem.mbemlevel.api.dto.request.CreerLeconRequest(
                    "Lesson 1",
                    "Lesson desc",
                    1,
                    15,
                    25,
                    true,
                    java.util.List.of(
                        new com.mbem.mbemlevel.api.dto.request.BlocContenuRequest(
                            com.mbem.mbemlevel.domain.cours.TypeBloc.TEXTE_HTML,
                            1,
                            "Content text",
                            null, null, null, null, null, null, null, null, null, null, null
                        )
                    ),
                    null
                )
            )
        );

        UUID coursId = creerCoursCompletUC.executer(req, formateurId);
        org.junit.jupiter.api.Assertions.assertNotNull(coursId);

        var coursOpt = coursJpaRepo.findById(coursId);
        org.junit.jupiter.api.Assertions.assertTrue(coursOpt.isPresent());
        org.junit.jupiter.api.Assertions.assertEquals(1, coursOpt.get().getNbLecons());

        var lecons = leconRepo.findByCoursIdOrderByOrdreAsc(coursId);
        org.junit.jupiter.api.Assertions.assertEquals(1, lecons.size());
        org.junit.jupiter.api.Assertions.assertEquals("Lesson 1", lecons.get(0).getTitre());
    }
}
