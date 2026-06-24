package com.mbem.mbemlevel.domain.cours;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Agrégat Catégorie — thème principal d'un cours. */
public class Categorie extends AggregateRoot {
    private String nom;
    private String description;
    private String icone;

    public static Categorie creer(String nom, String description) {
        if (nom == null || nom.isBlank()) throw new IllegalArgumentException("Nom obligatoire");
        Categorie c = new Categorie(); c.nom = nom.trim(); c.description = description; return c;
    }

      public Categorie() {
        super();
    }
 

    public Categorie(UUID id, String nom, String description, String icone,
                     LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua); this.nom = nom; this.description = description; this.icone = icone;
    }
    public String getNom()         { return nom; }
    public String getDescription() { return description; }
    public String getIcone()       { return icone; }
}
