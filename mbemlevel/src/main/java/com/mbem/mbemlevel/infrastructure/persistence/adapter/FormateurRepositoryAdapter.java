package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.FormateurRepository;
import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.user.Formateur;
import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class FormateurRepositoryAdapter implements FormateurRepository {

    private final UtilisateurJpaRepository jpaRepository;

    @Override
    @Transactional(readOnly = true)
    public Optional<Formateur> findById(UUID id) {
        return jpaRepository.findById(id)
                .filter(entity -> entity.getRole() == Role.FORMATEUR)
                .map(this::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Formateur> findByEmail(String email) {
        return jpaRepository.findByEmailIgnoreCase(email)
                .filter(entity -> entity.getRole() == Role.FORMATEUR)
                .map(this::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsByEmail(String email) {
        return findByEmail(email).isPresent();
    }

    @Override
    @Transactional
    public Formateur save(Formateur formateur) {
        UtilisateurJpaEntity entity = jpaRepository.findById(formateur.getId())
                .map(existing -> updateEntity(formateur, existing))
                .orElseGet(() -> toEntity(formateur));
        return toDomain(jpaRepository.save(entity));
    }

    @Override
    @Transactional(readOnly = true)
    public List<Formateur> findAll() {
        return jpaRepository.findAll().stream()
                .filter(entity -> entity.getRole() == Role.FORMATEUR)
                .map(this::toDomain)
                .collect(Collectors.toList());
    }

    private Formateur toDomain(UtilisateurJpaEntity entity) {
        return new Formateur(
                entity.getId(),
                entity.getPrenom(),
                entity.getNom(),
                entity.getEmail(),
                entity.getMotDePasseHache(),
                entity.getStatut(),
                entity.getTentativesEchouees(),
                entity.getBloqueJusquAu(),
                entity.getDerniereConnexion(),
                entity.isEmailVerifie(),
                entity.getTokenVerificationEmail(),
                entity.getTokenVerificationEmailExpireAt(),
                entity.getTelephone(),
                entity.getCreatedAt(),
                entity.getUpdatedAt(),
                entity.getSpecialite(),
                entity.getBiographie(),
                entity.getNoteGlobale() != null ? entity.getNoteGlobale().doubleValue() : null
        );
    }

    private UtilisateurJpaEntity toEntity(Formateur formateur) {
        return UtilisateurJpaEntity.builder()
                .id(formateur.getId())
                .prenom(formateur.getPrenom())
                .nom(formateur.getNom())
                .email(formateur.getEmail())
                .motDePasseHache(formateur.getMotDePasseHache())
                .emailVerifie(formateur.isEmailVerifie())
                .tokenVerificationEmail(formateur.getTokenVerificationEmail())
                .telephone(formateur.getTelephone())
                .role(Role.FORMATEUR)
                .statut(formateur.getStatut())
                .tentativesEchouees(formateur.getTentativesEchouees())
                .bloqueJusquAu(formateur.getBloqueJusquAu())
                .derniereConnexion(formateur.getDerniereConnexion())
                .specialite(formateur.getSpecialite())
                .biographie(formateur.getBiographie())
                .noteGlobale(formateur.getNoteGlobale() != null ? BigDecimal.valueOf(formateur.getNoteGlobale()) : null)
                .build();
    }

    private UtilisateurJpaEntity updateEntity(Formateur formateur, UtilisateurJpaEntity entity) {
        entity.setPrenom(formateur.getPrenom());
        entity.setNom(formateur.getNom());
        entity.setMotDePasseHache(formateur.getMotDePasseHache());
        entity.setEmailVerifie(formateur.isEmailVerifie());
        entity.setTokenVerificationEmail(formateur.getTokenVerificationEmail());
        entity.setTelephone(formateur.getTelephone());
        entity.setRole(Role.FORMATEUR);
        entity.setStatut(formateur.getStatut());
        entity.setTentativesEchouees(formateur.getTentativesEchouees());
        entity.setBloqueJusquAu(formateur.getBloqueJusquAu());
        entity.setDerniereConnexion(formateur.getDerniereConnexion());
        entity.setSpecialite(formateur.getSpecialite());
        entity.setBiographie(formateur.getBiographie());
        entity.setNoteGlobale(formateur.getNoteGlobale() != null ? BigDecimal.valueOf(formateur.getNoteGlobale()) : null);
        return entity;
    }
}
