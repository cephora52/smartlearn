package com.mbem.mbemlevel.infrastructure.persistence.entity;

import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.data.annotation.CreatedDate;
import jakarta.persistence.Id; 
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import com.mbem.mbemlevel.domain.shared.enums.StatutPaiement;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "paiements", uniqueConstraints = @UniqueConstraint(columnNames = { "apprenant_id", "cours_id" }))
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaiementJpaEntity {
    @Id
    private UUID id;
    @Column(name = "apprenant_id", nullable = false)
    private UUID apprenantId;
    @Column(name = "cours_id", nullable = false)
    private UUID coursId;
    @Column(name = "montant_total", nullable = false)
    private long montantTotal;
    @Column(name = "montant_paye", nullable = false)
    private long montantPaye;
    @Enumerated(EnumType.STRING)
    @Column(name = "mode_paiement", nullable = false, length = 20)
    private ModePaiement modePaiement;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutPaiement statut;
    @Column(name = "admin_id")
    private UUID adminId;
    @Column(name = "acces_active", nullable = false)
    private boolean accesActive;
    @Column(name = "date_activation")
    private LocalDateTime dateActivation;
    @Column(name = "notes_admin", columnDefinition = "TEXT")
    private String notesAdmin;
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
