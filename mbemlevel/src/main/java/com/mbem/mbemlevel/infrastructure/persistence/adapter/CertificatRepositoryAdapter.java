package com.mbem.mbemlevel.infrastructure.persistence.adapter;
import com.mbem.mbemlevel.application.port.out.CertificatRepository;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CertificatJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CertificatJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.stream.Collectors;
@Component @RequiredArgsConstructor
public class CertificatRepositoryAdapter implements CertificatRepository {
    private final CertificatJpaRepository repo;
    @Override @Transactional(readOnly=true)
    public Optional<Certificat> findById(UUID id)   { return repo.findById(id).map(this::toDomain); }
    @Override @Transactional(readOnly=true)
    public Optional<Certificat> findByCode(String c){ return repo.findByCodeVerification(c).map(this::toDomain); }
    @Override @Transactional(readOnly=true)
    public Optional<Certificat> findByApprenantAndCours(UUID a, UUID c) {
        return repo.findByApprenantIdAndCoursId(a,c).map(this::toDomain);
    }
    @Override @Transactional(readOnly=true)
    public List<Certificat> findByApprenant(UUID a) {
        return repo.findByApprenantId(a).stream().map(this::toDomain).collect(Collectors.toList());
    }
    @Override @Transactional
    public Certificat save(Certificat c) { return toDomain(repo.save(toEntity(c))); }
    private Certificat toDomain(CertificatJpaEntity e) {
        return new Certificat(e.getId(),e.getApprenantId(),e.getCoursId(),
            e.getCodeVerification(),e.getLienPdf(),e.getDateEmission(),
            e.getCreatedAt(),e.getUpdatedAt());
    }
    private CertificatJpaEntity toEntity(Certificat c) {
        return CertificatJpaEntity.builder().id(c.getId())
            .apprenantId(c.getApprenantId()).coursId(c.getCoursId())
            .codeVerification(c.getCodeVerification())
            .lienPdf(c.getLienPdf()).dateEmission(c.getDateEmission()).build();
    }
}
