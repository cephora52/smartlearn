package com.mbem.mbemlevel.infrastructure.persistence.entity;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="messages_communaute")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MessageCommunauteJpaEntity {
    @Id private UUID id;
    @Column(name="cours_id",nullable=false)  private UUID coursId;
    @Column(name="auteur_id",nullable=false) private UUID auteurId;
    @Column(name="parent_id")               private UUID parentId;
    @Column(nullable=false,columnDefinition="TEXT") private String contenu;
    @Column(name="est_question",nullable=false) private boolean estQuestion;
    @Column(name="est_resolu",nullable=false)   private boolean estResolu;
    @Column(name="est_modere",nullable=false)   private boolean estModere;
    @Column(name="nb_likes",nullable=false)     private int nbLikes;
    @Column(name="nb_signalements",nullable=false) private int nbSignalements;
    @Column(name="est_masque",nullable=false)       private boolean estMasque;
    @Column(name="created_at",nullable=false,updatable=false) private LocalDateTime createdAt;
    @Column(name="updated_at",nullable=false) private LocalDateTime updatedAt;
    @PrePersist protected void onCreate() {
        if (id==null) id=UUID.randomUUID();
        if (createdAt==null) createdAt=LocalDateTime.now();
        if (updatedAt==null) updatedAt=createdAt;
    }
    @PreUpdate protected void onUpdate() { updatedAt=LocalDateTime.now(); }
}
