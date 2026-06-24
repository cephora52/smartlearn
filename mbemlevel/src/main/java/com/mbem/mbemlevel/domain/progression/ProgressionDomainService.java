package com.mbem.mbemlevel.domain.progression;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * Service domaine Progression — logique métier XP, streak et badges.
 * Stateless — injecté dans les use cases.
 */
public class ProgressionDomainService {

    // ── XP ──────────────────────────────────────────────────────────────────

    /**
     * Calcule l'XP total cumulé après validation d'une leçon.
     * Le streak multiplie les XP si actif.
     *
     * @param xpActuel   XP déjà cumulé avant cette leçon
     * @param xpLecon    XP de base de la leçon
     * @param streakJours Nombre de jours consécutifs actifs
     * @return Nouvel XP total
     */
    public int calculerNouvelXP(int xpActuel, int xpLecon, int streakJours) {
        // Bonus streak : +10% par semaine complète, plafonné à +50%
        double multiplicateur = 1.0 + Math.min(0.5, (streakJours / 7) * 0.10);
        int xpAvecBonus = (int) Math.round(xpLecon * multiplicateur);
        return xpActuel + xpAvecBonus;
    }

    // ── STREAK ──────────────────────────────────────────────────────────────

    /**
     * Calcule le streak (série de jours consécutifs).
     *
     * @param dernierAcces    Date du dernier accès enregistré
     * @param streakActuel    Streak actuel en jours
     * @return Nouveau streak
     */
    public int calculerNouveauStreak(LocalDate dernierAcces, int streakActuel) {
        if (dernierAcces == null) return 1; // Premier accès
        long joursDepuis = ChronoUnit.DAYS.between(dernierAcces, LocalDate.now());

        if (joursDepuis == 0) return streakActuel;       // Même jour — pas de changement
        if (joursDepuis == 1) return streakActuel + 1;   // Lendemain — streak continue
        return 1;                                          // Gap > 1 jour — reset à 1
    }

    /**
     * Vérifie si le streak est "actif" (dernière activité aujourd'hui ou hier).
     */
    public boolean estStreakActif(LocalDate dernierAcces) {
        if (dernierAcces == null) return false;
        long joursDepuis = ChronoUnit.DAYS.between(dernierAcces, LocalDate.now());
        return joursDepuis <= 1;
    }

    // ── POURCENTAGE ─────────────────────────────────────────────────────────

    /**
     * Calcule le pourcentage de progression.
     *
     * @param nbLeconsTerminees Nombre de leçons validées (QCM >= 70%)
     * @param nbLeconsTotales   Nombre total de leçons du cours
     * @return Pourcentage de 0.0 à 100.0
     */
    public double calculerPourcentage(int nbLeconsTerminees, int nbLeconsTotales) {
        if (nbLeconsTotales <= 0) return 0.0;
        return Math.min(100.0, Math.round((double) nbLeconsTerminees / nbLeconsTotales * 100.0 * 10.0) / 10.0);
    }

    /**
     * Vérifie si le seuil de paiement est atteint.
     *
     * @param pourcentage    Pourcentage actuel (0.0–100.0)
     * @param seuilPaiement  Seuil configuré (0.01–1.0)
     * @return true si paiement requis
     */
    public boolean estSeuilAtteint(double pourcentage, double seuilPaiement) {
        return pourcentage >= (seuilPaiement * 100.0);
    }

    // ── BADGES ──────────────────────────────────────────────────────────────

    /**
     * Vérifie si un badge spécifique doit être attribué.
     *
     * @param typeBadge       Le badge à évaluer
     * @param xpTotal         XP total de l'apprenant
     * @param streakJours     Streak actuel
     * @param badgesExistants Liste des badges déjà obtenus
     * @return true si le badge doit être attribué
     */
    public boolean doitAttribuerBadge(String typeBadge, int xpTotal,
                                       int streakJours, List<String> badgesExistants) {
        if (badgesExistants.contains(typeBadge)) return false; // Déjà obtenu
        return switch (typeBadge) {
            case "XP_100"        -> xpTotal >= 100;
            case "XP_500"        -> xpTotal >= 500;
            case "XP_1000"       -> xpTotal >= 1000;
            case "XP_5000"       -> xpTotal >= 5000;
            case "STREAK_7"      -> streakJours >= 7;
            case "STREAK_30"     -> streakJours >= 30;
            case "PREMIER_COURS" -> xpTotal > 0; // A commencé au moins un cours
            default              -> false;
        };
    }

    /**
     * Retourne tous les badges à attribuer selon l'état actuel.
     */
    public List<String> calculerBadgesAAttribuer(int xpTotal, int streakJours,
                                                   List<String> badgesExistants) {
        return List.of("XP_100","XP_500","XP_1000","XP_5000",
                        "STREAK_7","STREAK_30","PREMIER_COURS")
            .stream()
            .filter(b -> doitAttribuerBadge(b, xpTotal, streakJours, badgesExistants))
            .toList();
    }
}
