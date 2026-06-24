package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.mapper.UtilisateurJpaMapper;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Adaptateur sortant pour les utilisateurs.
 * Traduit les appels domaine en opérations JPA.
 */
@Component
@RequiredArgsConstructor
public class UtilisateurRepositoryAdapter implements UtilisateurRepository {

    private final UtilisateurJpaRepository jpaRepository;
    private final UtilisateurJpaMapper mapper;

    @Override
    @Transactional(readOnly = true)
    public Optional<Utilisateur> findById(UUID id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Utilisateur> findByEmail(String email) {
        return jpaRepository.findByEmailIgnoreCase(email).map(mapper::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsByEmail(String email) {
        return jpaRepository.existsByEmailIgnoreCase(email);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Utilisateur> findByTokenVerificationEmail(String token) {
        return jpaRepository.findByTokenVerificationEmail(token)
                .map(mapper::toDomain);
    }

    @Override
    @Transactional
    public Utilisateur save(Utilisateur utilisateur) {
        Optional<UtilisateurJpaEntity> existing = jpaRepository.findById(utilisateur.getId());

        UtilisateurJpaEntity entity;
        if (existing.isPresent()) {
            // UPDATE : utiliser updateJpaEntity pour préserver l'état Hibernate
            entity = existing.get();
            mapper.updateJpaEntity(utilisateur, entity);
        } else {
            // INSERT
            entity = mapper.toJpaEntity(utilisateur);
        }

        return mapper.toDomain(jpaRepository.save(entity));
    }

    @Override
    @Transactional(readOnly = true)
    public List<Utilisateur> findApprenantsDisponibles() {
        return jpaRepository.findApprenantsDisponibles()
                .stream().map(mapper::toDomain).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<Utilisateur> findAll() {
        return jpaRepository.findAll()
                .stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }
}
