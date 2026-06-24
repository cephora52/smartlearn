// =============================================================================
// MbemNova — infrastructure/cache/CacheKeyConstants.java
// Constantes de toutes les clés Redis centralisées en un seul endroit.
// Convention : mbemnova:{domaine}:{identifiant}
// =============================================================================
package com.mbem.mbemlevel.infrastructure.cache;

/**
 * Constantes des clés Redis MbemNova.
 * Centraliser ici évite les fautes de frappe et facilite le monitoring.
 *
 * <h3>TTL par catégorie</h3>
 * <ul>
 *   <li>JWT blacklist : TTL = durée restante du token (auto-expiration)</li>
 *   <li>Rate limiting : TTL = fenêtre configurée (60s, 3600s…)</li>
 *   <li>Catalogue cours : 10 minutes (peu de changements)</li>
 *   <li>Progression : 5 minutes (mise à jour fréquente)</li>
 *   <li>Places session : 30 secondes (données très volatiles)</li>
 * </ul>
 */
public final class CacheKeyConstants {

    private CacheKeyConstants() { /* Classe utilitaire */ }

    private static final String APP = "mbemnova";

    // ── JWT Blacklist ─────────────────────────────────────────────────────────
    /** mbemnova:jwt:blacklist:{jti} — utilisé par TokenBlacklistService */
    public static String jwtBlacklist(String jti) {
        return APP + ":jwt:blacklist:" + jti;
    }

    // ── Rate Limiting ─────────────────────────────────────────────────────────
    /** mbemnova:rl:{endpoint}:{ip} — compteur Bucket4j */
    public static String rateLimitKey(String endpoint, String ip) {
        return APP + ":rl:" + endpoint + ":" + ip;
    }

    // ── Catalogue Cours ───────────────────────────────────────────────────────
    /** mbemnova:cours:catalogue:{hashFiltres} — cache 10 min */
    public static String catalogueCours(String hashFiltres) {
        return APP + ":cours:catalogue:" + hashFiltres;
    }

    /** mbemnova:cours:{coursId} — détail d'un cours */
    public static String detailCours(String coursId) {
        return APP + ":cours:" + coursId;
    }

    // ── Progression ───────────────────────────────────────────────────────────
    /** mbemnova:progression:{userId}:{coursId} — cache 5 min */
    public static String progression(String userId, String coursId) {
        return APP + ":progression:" + userId + ":" + coursId;
    }

    // ── Session ───────────────────────────────────────────────────────────────
    /** mbemnova:session:places:{sessionId} — places disponibles cache 30s */
    public static String placesSession(String sessionId) {
        return APP + ":session:places:" + sessionId;
    }

    // ── Utilisateur ───────────────────────────────────────────────────────────
    /** mbemnova:user:{userId} — profil cache 5 min */
    public static String utilisateur(String userId) {
        return APP + ":user:" + userId;
    }

    // ── Statistiques Admin ────────────────────────────────────────────────────
    /** mbemnova:admin:stats — tableau de bord admin cache 1 min */
    public static String statsAdmin() {
        return APP + ":admin:stats";
    }
}
