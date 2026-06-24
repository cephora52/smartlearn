package com.mbem.mbemlevel.infrastructure.persistence.entity;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="certificats",
    uniqueConstraints=@UniqueConstraint(columnNames={"apprenant_id","cours_id"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CertificatJpaEntity {
    @Id private UUID id;
    @Column(name="apprenant_id",nullable=false) private UUID apprenantId;
    @Column(name="cours_id",nullable=false)     private UUID coursId;
    @Column(name="code_verification",nullable=false,unique=true,length=50) private String codeVerification;
    @Column(name="lien_pdf",length=500) private String lienPdf;
    @Column(name="date_emission",nullable=false) private LocalDateTime dateEmission;
    @Column(name="created_at",nullable=false,updatable=false) private LocalDateTime createdAt;
    @Column(name="updated_at",nullable=false) private LocalDateTime updatedAt;
    @PrePersist protected void onCreate() {
        if (id==null) id=UUID.randomUUID();
        if (createdAt==null) createdAt=LocalDateTime.now();
        if (updatedAt==null) updatedAt=createdAt;
    }
    @PreUpdate protected void onUpdate() { updatedAt=LocalDateTime.now(); }
}
