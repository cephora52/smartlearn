package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.MessageCommunauteJpaEntity;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.UUID;
public interface MessageCommunauteJpaRepository
    extends JpaRepository<MessageCommunauteJpaEntity, UUID> {
    /** Questions racines d'un cours, non modérées, triées par likes. */
    @Query("SELECT m FROM MessageCommunauteJpaEntity m " +
           "WHERE m.coursId=:cid AND m.parentId IS NULL AND m.estModere=false " +
           "ORDER BY m.nbLikes DESC, m.createdAt DESC")
    Page<MessageCommunauteJpaEntity> findQuestions(
        @Param("cid") UUID coursId, Pageable pageable);
    /** Réponses à une question. */
    @Query("SELECT m FROM MessageCommunauteJpaEntity m " +
           "WHERE m.parentId=:pid AND m.estModere=false ORDER BY m.createdAt ASC")
    Page<MessageCommunauteJpaEntity> findReponses(
        @Param("pid") UUID parentId, Pageable pageable);
}
