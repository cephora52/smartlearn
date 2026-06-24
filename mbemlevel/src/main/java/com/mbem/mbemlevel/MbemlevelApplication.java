package com.mbem.mbemlevel;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
/**
 * MbemNova — Point d'entrée de l'application Spring Boot 4.
 *
 * @EnableAsync : active les @Async dans les event handlers
 *               (email bienvenue, WhatsApp, etc.)
 */
@SpringBootApplication
@EnableAsync
public class MbemlevelApplication {
    public static void main(String[] args) {
        SpringApplication.run(MbemlevelApplication.class, args);
    }
}
