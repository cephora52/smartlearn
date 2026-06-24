package com.mbem.mbemlevel.infrastructure.persistence.entity;
import com.mbem.mbemlevel.domain.shared.enums.CanalNotification;
import com.mbem.mbemlevel.domain.shared.enums.TypeNotification;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="notifications")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class NotificationJpaEntity {
    @Id private UUID id;
    @Column(name="utilisateur_id",nullable=false) private UUID utilisateurId;
    @Enumerated(EnumType.STRING) @Column(name="type_notif",nullable=false,length=50) private TypeNotification typeNotif;
    @Enumerated(EnumType.STRING) @Column(nullable=false,length=20) private CanalNotification canal;
    @Column(nullable=false,length=200) private String titre;
    @Column(columnDefinition="TEXT") private String contenu;
    @Column(name="est_lue",nullable=false) private boolean estLue;
    @Column(name="date_lecture") private LocalDateTime dateLecture;
    @Column(name="lien_action",length=500) private String lienAction;
    @Column(name="created_at",nullable=false,updatable=false) private LocalDateTime createdAt;
    @Column(name="updated_at",nullable=false) private LocalDateTime updatedAt;
    @PrePersist protected void onCreate() {
        if (id==null) id=UUID.randomUUID();
        if (createdAt==null) createdAt=LocalDateTime.now();
        if (updatedAt==null) updatedAt=createdAt;
    }
    @PreUpdate protected void onUpdate() { updatedAt=LocalDateTime.now(); }
}
