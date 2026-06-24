package com.mbem.mbemlevel.domain.session;
import java.util.List;
/** Règles métier sessions — détection conflits horaires. */
import org.springframework.stereotype.Service;

@Service
public class SessionDomainService {
    /**
     * Vérifie si deux créneaux se chevauchent (même jour, heures qui se recoupent).
     */
    public boolean creneauxSeChevauchet(Creneau c1, Creneau c2) {
        if (c1.getJourSemaine() != c2.getJourSemaine()) return false;
        return c1.getHeureDebut().isBefore(c2.getHeureFin())
            && c2.getHeureDebut().isBefore(c1.getHeureFin());
    }
    /** Vérifie qu'un apprenant n'a pas de conflit avec ses créneaux existants. */
    public boolean aConflit(Creneau nouveau, List<Creneau> existants) {
        return existants.stream().anyMatch(e -> creneauxSeChevauchet(nouveau, e));
    }
}
