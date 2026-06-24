// MbemNova — domain/user/UserDomainService.java
package com.mbem.mbemlevel.domain.user;

import com.mbem.mbemlevel.domain.user.valueobject.LienParrainage;

/**
 * Service domaine — règles métier qui impliquent plusieurs entités User
 * ou qui ne rentrent pas naturellement dans un seul agrégat.
 */
public class UserDomainService {

    /**
     * Génère un code de parrainage unique pour un apprenant.
     * Le use case vérifie l'unicité en base avant de persister.
     */
    public LienParrainage genererCodeParrainage() {
        return LienParrainage.generer();
    }

    /**
     * Vérifie qu'un apprenant peut parrainer (doit être CERTIFIE ou avoir fini un module).
     */
    public boolean peutParrainer(Apprenant apprenant) {
        return apprenant.getXpTotal() >= 100;  // A complété au moins un module
    }
}
