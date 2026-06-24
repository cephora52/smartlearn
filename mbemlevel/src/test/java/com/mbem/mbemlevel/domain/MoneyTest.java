package com.mbem.mbemlevel.domain;

import com.mbem.mbemlevel.domain.shared.Money;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

@DisplayName("Money — Value Object")
class MoneyTest {

    @Test @DisplayName("of(50000) = 50000 FCFA")
    void of_creeMontantCorrect() {
        assertThat(Money.of(50_000).toLong()).isEqualTo(50_000L);
    }

    @Test @DisplayName("pct(30) sur 50000 = 15000")
    void pct_calculePourcentageCorrect() {
        assertThat(Money.of(50_000).pct(30).toLong()).isEqualTo(15_000L);
    }

    @Test @DisplayName("plus() — immuable, retourne nouveau Money")
    void plus_retourveNouvelObjet() {
        Money a = Money.of(10_000);
        Money b = Money.of(5_000);
        Money c = a.plus(b);
        assertThat(c.toLong()).isEqualTo(15_000L);
        assertThat(a.toLong()).isEqualTo(10_000L); // a inchangé
    }

    @Test @DisplayName("minus() avec résultat négatif → IllegalArgumentException")
    void minus_montantNegatif_lanceException() {
        assertThatThrownBy(() -> Money.of(5_000).minus(Money.of(10_000)))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test @DisplayName("equals() basé sur la valeur, pas la référence")
    void equals_baseSurValeur() {
        assertThat(Money.of(1_000)).isEqualTo(Money.of(1_000));
        assertThat(Money.of(1_000)).isNotEqualTo(Money.of(2_000));
    }

    @Test @DisplayName("toDisplay() retourne le format '50 000 FCFA'")
    void toDisplay_formatCorrect() {
        assertThat(Money.of(50_000).toDisplay()).contains("FCFA");
    }

    @Test @DisplayName("ZERO.isZero() = true")
    void zero_isZero() {
        assertThat(Money.ZERO.isZero()).isTrue();
        assertThat(Money.of(1).isZero()).isFalse();
    }

    @Test @DisplayName("Montant négatif → IllegalArgumentException à la construction")
    void montantNegatif_lanceException() {
        assertThatThrownBy(() -> Money.of(-1))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("négatif");
    }
}
