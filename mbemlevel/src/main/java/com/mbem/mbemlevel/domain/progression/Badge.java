package com.mbem.mbemlevel.domain.progression;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Badge de gamification attribué à un apprenant. */
public class Badge extends AggregateRoot {
    private UUID   apprenantId;
    private String typeBadge;   // PREMIER_COURS, STREAK_7, XP_1000, CERTIFIE
    private String description;

    public static Badge attribuer(UUID apprenantId, String type, String desc) {
        Badge b = new Badge(); b.apprenantId = apprenantId;
        b.typeBadge = type; b.description = desc; return b;
    }
    
  public Badge() {
        super();
    }

    public Badge(UUID id, UUID apprenantId, String typeBadge, String description,
                 LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.apprenantId = apprenantId; this.typeBadge = typeBadge; this.description = description;
    }
    public UUID   getApprenantId() { return apprenantId; }
    public String getTypeBadge()   { return typeBadge; }
    public String getDescription() { return description; }
}
