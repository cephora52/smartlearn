package com.mbem.mbemlevel.api.config;
import io.swagger.v3.oas.models.*;
import io.swagger.v3.oas.models.info.*;
import io.swagger.v3.oas.models.security.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
/**
 * Configuration Swagger UI avec authentification JWT Bearer.
 * Désactivé en production via application-prod.yaml.
 */
@Configuration
public class OpenApiConfig {
    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("MbemNova API")
                .version("1.0.0")
                .description("Plateforme EdTech — Formation tech Afrique Centrale")
                .contact(new Contact().email("dev@mbemnova.com")))
            .addSecurityItem(new SecurityRequirement().addList("Bearer"))
            .components(new Components().addSecuritySchemes("Bearer",
                new SecurityScheme()
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")
                    .description("JWT généré par POST /api/v1/auth/login")));
    }
}
