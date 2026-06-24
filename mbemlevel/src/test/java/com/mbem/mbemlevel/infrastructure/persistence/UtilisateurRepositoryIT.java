package com.mbem.mbemlevel.infrastructure.persistence;

import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.*;

/**
 * Test d'intégration avec PostgreSQL réel via Testcontainers.
 * La datasource TC est configurée dans application-test.yaml :
 *   url: jdbc:tc:postgresql:16:///mbemnova_test?TC_REUSABLE=true
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
@DisplayName("UtilisateurRepository — Intégration PostgreSQL")
class UtilisateurRepositoryIT {

    @Autowired
    private UtilisateurRepository repository;

    @Test
    @DisplayName("save() + findByEmail() insensible à la casse")
    void saveEtFindByEmail_insensibleCasse() {
        Utilisateur u = Utilisateur.creer("Alice", "ALICE@TEST.COM", "$2a$12$hash");
        repository.save(u);

        // Recherche en minuscules
        var found = repository.findByEmail("alice@test.com");
        assertThat(found).isPresent();
        assertThat(found.get().getPrenom()).isEqualTo("Alice");
    }

    @Test
    @DisplayName("existsByEmail() retourne true pour email connu")
    void existsByEmail_retourneTrue() {
        Utilisateur u = Utilisateur.creer("Bob", "bob@test.com", "hash");
        repository.save(u);
        assertThat(repository.existsByEmail("bob@test.com")).isTrue();
        assertThat(repository.existsByEmail("inconnu@test.com")).isFalse();
    }

    @Test
    @DisplayName("save() UPDATE préserve l'ID original")
    void save_update_preserveId() {
        Utilisateur u = Utilisateur.creer("Carol", "carol@test.com", "hash");
        Utilisateur saved = repository.save(u);
        saved.enregistrerConnexionReussie();
        Utilisateur updated = repository.save(saved);
        assertThat(updated.getId()).isEqualTo(saved.getId());
    }
}
