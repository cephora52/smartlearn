package com.mbem.mbemlevel.domain;

import com.mbem.mbemlevel.domain.event.ApprenantInscritEvent;
import com.mbem.mbemlevel.domain.event.CompteSuspenduEvent;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.shared.enums.StatutApprenant;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

/**
 * Tests unitaires de l'agrégat Utilisateur.
 * Zéro dépendance Spring — Java pur, très rapides.
 */
@DisplayName("Utilisateur — Agrégat Domain")
class UtilisateurTest {

    // ── Factory method creer() ────────────────────────────────────────────────

    @Nested
    @DisplayName("Création")
    class Creation {

        @Test
        @DisplayName("creer() initialise le statut INSCRIT et le rôle APPRENANT")
        void creer_initialiseStatutEtRole() {
            Utilisateur u = Utilisateur.creer("Alice", "alice@test.com", "hash123");
            assertThat(u.getStatut()).isEqualTo(StatutApprenant.INSCRIT);
            assertThat(u.getRole()).isEqualTo(Role.APPRENANT);
            assertThat(u.isEmailVerifie()).isFalse();
        }

        @Test
        @DisplayName("creer() enregistre ApprenantInscritEvent")
        void creer_enregistreDomainEvent() {
            Utilisateur u = Utilisateur.creer("Bob", "bob@test.com", "hash");
            assertThat(u.getDomainEvents()).hasSize(1);
            assertThat(u.getDomainEvents().get(0)).isInstanceOf(ApprenantInscritEvent.class);
            ApprenantInscritEvent evt = (ApprenantInscritEvent) u.getDomainEvents().get(0);
            assertThat(evt.email()).isEqualTo("bob@test.com");
        }

        @Test
        @DisplayName("creer() avec prénom blank → IllegalArgumentException")
        void creer_prenomBlank_lanceException() {
            assertThatThrownBy(() -> Utilisateur.creer("", "x@x.com", "hash"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("obligatoire");
        }

        @Test
        @DisplayName("creer() normalise l'email en minuscules")
        void creer_normaliseEmailMinuscules() {
            Utilisateur u = Utilisateur.creer("Ali", "ALI@TEST.COM", "hash");
            assertThat(u.getEmail()).isEqualTo("ali@test.com");
        }
    }

    // ── Protection brute-force ────────────────────────────────────────────────

    @Nested
    @DisplayName("Protection brute-force")
    class BruteForce {

        @Test
        @DisplayName("Compte bloqué après 5 tentatives échouées")
        void blocageApres5Tentatives() {
            Utilisateur u = Utilisateur.creer("Test", "t@t.com", "hash");
            for (int i = 0; i < 5; i++) {
                u.enregistrerConnexionEchouee(5, 30);
            }
            assertThat(u.estBloque()).isTrue();
        }

        @Test
        @DisplayName("Connexion réussie réinitialise le compteur")
        void connexionReussieReinitialiseCompteur() {
            Utilisateur u = Utilisateur.creer("Test", "t@t.com", "hash");
            u.enregistrerConnexionEchouee(5, 30);
            u.enregistrerConnexionEchouee(5, 30);
            u.enregistrerConnexionReussie();
            assertThat(u.getTentativesEchouees()).isZero();
            assertThat(u.estBloque()).isFalse();
        }

        @Test
        @DisplayName("Connexion réussie fait passer INSCRIT → ACTIF")
        void connexionReussiePasseStatutActif() {
            Utilisateur u = Utilisateur.creer("Test", "t@t.com", "hash");
            assertThat(u.getStatut()).isEqualTo(StatutApprenant.INSCRIT);
            u.enregistrerConnexionReussie();
            assertThat(u.getStatut()).isEqualTo(StatutApprenant.ACTIF);
        }
    }

    // ── Suspension ────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("Suspension et réactivation")
    class Suspension {

        @Test
        @DisplayName("suspendre() change le statut et publie CompteSuspenduEvent")
        void suspendre_publieEvent() {
            Utilisateur u = Utilisateur.creer("Eve", "eve@t.com", "hash");
            u.enregistrerConnexionReussie(); // INSCRIT → ACTIF
            u.clearDomainEvents();

            u.suspendre("Retard paiement");

            assertThat(u.getStatut()).isEqualTo(StatutApprenant.SUSPENDU);
            assertThat(u.getDomainEvents()).hasSize(1);
            assertThat(u.getDomainEvents().get(0)).isInstanceOf(CompteSuspenduEvent.class);
        }

        @Test
        @DisplayName("suspendre() sur compte déjà suspendu → IllegalStateException")
        void suspendre_dejaeSuspendu_lanceException() {
            Utilisateur u = Utilisateur.creer("Eve", "eve@t.com", "hash");
            u.enregistrerConnexionReussie();
            u.suspendre("Raison 1");
            assertThatThrownBy(() -> u.suspendre("Raison 2"))
                .isInstanceOf(IllegalStateException.class);
        }

        @Test
        @DisplayName("Un compte suspendu peut se connecter mais pas accéder aux cours")
        void suspendu_peutSeConnecterMaisPasAccederCours() {
            Utilisateur u = Utilisateur.creer("Eve", "eve@t.com", "hash");
            u.enregistrerConnexionReussie();
            u.suspendre(null);
            assertThat(u.peutSeConnecter()).isTrue();
            assertThat(u.peutAccederAuxCours()).isFalse();
        }

        @Test
        @DisplayName("reactiver() remet le statut ACTIF")
        void reactiver_repasseActif() {
            Utilisateur u = Utilisateur.creer("Eve", "eve@t.com", "hash");
            u.enregistrerConnexionReussie();
            u.suspendre(null);
            u.reactiver();
            assertThat(u.getStatut()).isEqualTo(StatutApprenant.ACTIF);
            assertThat(u.peutAccederAuxCours()).isTrue();
        }
    }

    // ── Changement de rôle ────────────────────────────────────────────────────

    @Nested
    @DisplayName("Changement de rôle")
    class ChangementRole {

        @Test
        @DisplayName("Un ADMIN peut promouvoir APPRENANT → FORMATEUR")
        void admin_peutPromouvroirFormateur() {
            Utilisateur u = Utilisateur.creer("Carol", "carol@t.com", "hash");
            u.changerRole(Role.FORMATEUR, Role.ADMIN);
            assertThat(u.getRole()).isEqualTo(Role.FORMATEUR);
        }

        @Test
        @DisplayName("Un ADMIN ne peut pas attribuer SUPER_ADMIN")
        void admin_nepeutPasAttribuerSuperAdmin() {
            Utilisateur u = Utilisateur.creer("Carol", "carol@t.com", "hash");
            assertThatThrownBy(() -> u.changerRole(Role.SUPER_ADMIN, Role.ADMIN))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("SUPER_ADMIN");
        }

        @Test
        @DisplayName("Un SUPER_ADMIN peut attribuer SUPER_ADMIN")
        void superAdmin_peutAttribuerSuperAdmin() {
            Utilisateur u = Utilisateur.creer("Dan", "dan@t.com", "hash");
            assertThatNoException().isThrownBy(
                () -> u.changerRole(Role.SUPER_ADMIN, Role.SUPER_ADMIN));
        }
    }
}
