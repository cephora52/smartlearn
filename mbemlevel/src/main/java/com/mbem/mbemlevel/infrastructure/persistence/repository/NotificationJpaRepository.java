package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.NotificationJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.*;
public interface NotificationJpaRepository extends JpaRepository<NotificationJpaEntity, UUID> {
    List<NotificationJpaEntity> findByUtilisateurIdOrderByCreatedAtDesc(UUID userId);
    @Query("SELECT n FROM NotificationJpaEntity n WHERE n.utilisateurId=:uid AND n.estLue=false")
    List<NotificationJpaEntity> findNonLues(@Param("uid") UUID userId);
    @Modifying
    @Query("UPDATE NotificationJpaEntity n SET n.estLue=true WHERE n.utilisateurId=:uid")
    int marquerToutesLues(@Param("uid") UUID userId);
}
