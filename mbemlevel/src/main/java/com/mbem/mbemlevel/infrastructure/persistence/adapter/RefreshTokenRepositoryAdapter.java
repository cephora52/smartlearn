// =============================================================================
// MbemNova — infrastructure/persistence/adapter/RefreshTokenRepositoryAdapter.java
// Implémente RefreshTokenRepository via JPA.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.RefreshTokenRepository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.RefreshTokenJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.RefreshTokenJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class RefreshTokenRepositoryAdapter implements RefreshTokenRepository {

    private final RefreshTokenJpaRepository jpaRepository;

    @Override
    @Transactional
    public void sauvegarder(UUID utilisateurId, String tokenHache,
                            LocalDateTime expireLe, String ip, String userAgent) {
        jpaRepository.save(RefreshTokenJpaEntity.builder()
            .utilisateurId(utilisateurId)
            .tokenHache(tokenHache)
            .expireLe(expireLe)
            .estRevoque(false)
            .ipCreation(ip)
            .userAgent(userAgent)
            .build());
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<UUID> findUtilisateurIdByTokenHache(String tokenHache) {
        return jpaRepository.findByTokenHache(tokenHache)
            .filter(t -> !t.isEstRevoque() && t.getExpireLe().isAfter(LocalDateTime.now()))
            .map(RefreshTokenJpaEntity::getUtilisateurId);
    }

    @Override
    @Transactional
    public void revoquerToken(String tokenHache) {
        jpaRepository.findByTokenHache(tokenHache).ifPresent(t -> {
            t.setEstRevoque(true);
            jpaRepository.save(t);
        });
    }

    @Override
    @Transactional
    public int revoquerTousLesTokens(UUID utilisateurId) {
        return jpaRepository.revoquerTousTokensUtilisateur(utilisateurId);
    }

    @Override
    @Transactional
    public int nettoyerTokensExpires() {
        return jpaRepository.supprimerTokensExpiresetRevoques(LocalDateTime.now());
    }
}
