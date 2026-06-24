// =============================================================================
// MbemNova — infrastructure/persistence/adapter/ResetTokenRepositoryAdapter.java
// Implémente ResetTokenRepository via JPA.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.ResetTokenRepository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ResetTokenJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ResetTokenJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class ResetTokenRepositoryAdapter implements ResetTokenRepository {

    private final ResetTokenJpaRepository jpaRepository;

    @Override
    @Transactional
    public void sauvegarder(UUID utilisateurId, String tokenHache,
                            LocalDateTime expireLe, String ip) {
        jpaRepository.save(ResetTokenJpaEntity.builder()
            .utilisateurId(utilisateurId)
            .tokenHache(tokenHache)
            .expireLe(expireLe)
            .estUtilise(false)
            .ipDemande(ip)
            .build());
    }
   


    @Override
    @Transactional(readOnly = true)
    public Optional<UUID> findUtilisateurIdSiValide(String tokenHache, LocalDateTime maintenant) {
        return jpaRepository.findTokenValide(tokenHache, maintenant)
            .map(ResetTokenJpaEntity::getUtilisateurId);
    }


    // @Override
    // @Transactional
    // public void marquerUtilise(String tokenHache) {
    //     jpaRepository.findByTokenHache(tokenHache).ifPresent(t -> {
    //         t.setEstUtilise(true);
    //         t.setUtiliseLe(LocalDateTime.now());
    //         jpaRepository.save(t);
    //     });
    // }

     @Override
    @Transactional
    public void marquerUtilise(String tokenHache) {
        //  CORRIGÉ : utilise findTokenValide au lieu de findByTokenHache
        jpaRepository.findTokenValide(tokenHache, LocalDateTime.now())
            .ifPresent(t -> {
                t.setEstUtilise(true);
                t.setUtiliseLe(LocalDateTime.now());
                jpaRepository.save(t);
            });
    }

    // Helper pour ResetTokenJpaRepository (pas encore ajouté)
    // On reuse findTokenValide avec hash = tokenHache
    private Optional<ResetTokenJpaEntity> findByToken(String hash) {
        return jpaRepository.findTokenValide(hash, LocalDateTime.now().minusYears(10));
    }

    @Override
    @Transactional
    public int invaliderTousTokensUtilisateur(UUID utilisateurId) {
        return jpaRepository.invaliderTousTokensUtilisateur(utilisateurId);
    }

    @Override
    @Transactional
    public int nettoyerTokensExpires() {
        return jpaRepository.supprimerTokensExpires(LocalDateTime.now());
    }
}
