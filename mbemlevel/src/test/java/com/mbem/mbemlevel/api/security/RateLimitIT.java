package com.mbem.mbemlevel.api.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("test")
@DisplayName("Rate Limiting — Tests d'intégration")
class RateLimitIT {

    @Autowired private MockMvc mvc;

    @Test
    @DisplayName("Réponse 200 contient X-Rate-Limit-Remaining")
    void reponse_contientHeaderRateLimit() throws Exception {
        mvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"test@test.com\",\"motDePasse\":\"test\"}"))
            .andExpect(header().exists("X-Rate-Limit-Remaining"));
    }
}
