package com.mbem.mbemlevel.domain.cours;

import java.time.LocalDateTime;
import java.util.UUID;

import com.mbem.mbemlevel.domain.shared.AggregateRoot;

/** Module d'un cours — contient les leçons. */
public class Module extends AggregateRoot {
    private UUID coursId;
    private String titre;
    private String description;
    private int ordre;
    private boolean estVerrouille;
    private int xpBonus;

    public static Module creer(UUID coursId, String titre, int ordre, int xpBonus) {
        if (ordre < 1)
            throw new IllegalArgumentException("Ordre >= 1");
        Module m = new Module();
        m.coursId = coursId;
        m.titre = titre.trim();
        m.ordre = ordre;
        m.estVerrouille = true;
        m.xpBonus = xpBonus;
        return m;
    }

    public Module() {
        super();
    }

    public Module(UUID id, UUID coursId, String titre, String description, int ordre,
            boolean estVerrouille, int xpBonus, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.coursId = coursId;
        this.titre = titre;
        this.description = description;
        this.ordre = ordre;
        this.estVerrouille = estVerrouille;
        this.xpBonus = xpBonus;
    }

    public void deverrouiller() {
        this.estVerrouille = false;
        markUpdated();
    }

    public UUID getCoursId() {
        return coursId;
    }

    public String getTitre() {
        return titre;
    }

    public String getDescription() {
        return description;
    }

    public int getOrdre() {
        return ordre;
    }

    public boolean isEstVerrouille() {
        return estVerrouille;
    }

    public int getXpBonus() {
        return xpBonus;
    }
}
