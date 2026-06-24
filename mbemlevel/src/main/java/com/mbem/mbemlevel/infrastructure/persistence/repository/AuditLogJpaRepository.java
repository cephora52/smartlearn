// MbemNova — infrastructure/persistence/repository/AuditLogJpaRepository.java
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.AuditLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

/**
 * Repository pour les logs d'audit.
 *
 * IMPORTANT — Table immuable :
 * N'utiliser que la méthode save() héritée de JpaRepository.
 * delete(), deleteAll(), deleteById() ne doivent JAMAIS être appelées.
 * Un trigger PostgreSQL les bloquerait de toute façon (V8__create_securite.sql).
 * L'adaptateur AuditLogRepositoryAdapter n'expose que la méthode enregistrer().
 */
public interface AuditLogJpaRepository extends JpaRepository<AuditLogJpaEntity, UUID> {
    // Intentionnellement vide — seul save() est autorisé via l'adaptateur
}
