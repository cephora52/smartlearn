package com.mbem.mbemlevel.domain;

import com.mbem.mbemlevel.domain.event.SeuilPaiementAtteintEvent;
import com.mbem.mbemlevel.domain.progression.Progression;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.*;

@DisplayName("Progression — Agrégat Domain")
class ProgressionTest {

    private static final double SEUIL_30_PCT = 0.30;

    @Test
    @DisplayName("avancer() publie SeuilPaiementAtteintEvent quand seuil franchi")
    void avancer_publieEventSeuilAtteint() {
        Progression p = Progression.commencer(UUID.randomUUID(), UUID.randomUUID(), SEUIL_30_PCT);
        // Monter à 35% (au-dessus du seuil 30%)
        p.avancer(35.0, 25, "Alice", "a@t.com", "+237600000000", "Cours Java");
        assertThat(p.getDomainEvents()).hasSize(1);
        assertThat(p.getDomainEvents().get(0)).isInstanceOf(SeuilPaiementAtteintEvent.class);
    }

    @Test
    @DisplayName("SeuilPaiementAtteintEvent publié UNE SEULE fois même si avancer() rappelé")
    void avancer_eventSeuilPublieUneFois() {
        Progression p = Progression.commencer(UUID.randomUUID(), UUID.randomUUID(), SEUIL_30_PCT);
        p.avancer(35.0, 25, "Alice", "a@t.com", null, "Cours Java");
        p.clearDomainEvents();
        // Deuxième avancement — le seuil est déjà atteint
        p.avancer(50.0, 25, "Alice", "a@t.com", null, "Cours Java");
        assertThat(p.getDomainEvents()).isEmpty();
    }

    @Test
    @DisplayName("avancer() à 100% marque la date de completion")
    void avancer_100pct_marqueDateCompletion() {
        Progression p = Progression.commencer(UUID.randomUUID(), UUID.randomUUID(), SEUIL_30_PCT);
        p.activerPaiement();
        p.avancer(100.0, 25, "Alice", "a@t.com", null, "Cours Java");
        assertThat(p.estTermine()).isTrue();
        assertThat(p.getDateCompletion()).isNotNull();
    }

    @Test
    @DisplayName("peutAccederLeconSuivante() → false si seuil atteint et non payé")
    void peutAcceder_falseQuandSeuilAtteintNonPaye() {
        Progression p = Progression.commencer(UUID.randomUUID(), UUID.randomUUID(), SEUIL_30_PCT);
        p.avancer(35.0, 25, "Alice", "a@t.com", null, "Cours");
        assertThat(p.isEstPaye()).isFalse();
        assertThat(p.seuilAtteint()).isTrue();
        assertThat(p.peutAccederLeconSuivante()).isFalse();
    }

    @Test
    @DisplayName("peutAccederLeconSuivante() → true après activerPaiement()")
    void peutAcceder_trueApresActiverPaiement() {
        Progression p = Progression.commencer(UUID.randomUUID(), UUID.randomUUID(), SEUIL_30_PCT);
        p.avancer(35.0, 25, "Alice", "a@t.com", null, "Cours");
        p.activerPaiement();
        assertThat(p.peutAccederLeconSuivante()).isTrue();
    }
}
