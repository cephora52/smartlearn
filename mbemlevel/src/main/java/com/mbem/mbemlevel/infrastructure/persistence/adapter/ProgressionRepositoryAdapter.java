package com.mbem.mbemlevel.infrastructure.persistence.adapter;
import com.mbem.mbemlevel.application.port.out.ProgressionRepository;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ProgressionJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ProgressionJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
@Component @RequiredArgsConstructor
public class ProgressionRepositoryAdapter implements ProgressionRepository {
    private final ProgressionJpaRepository repo;

    @Override @Transactional(readOnly=true)
    public Optional<Progression> findByApprenantIdAndCoursId(UUID aid, UUID cid) {
        return repo.findByApprenantIdAndCoursId(aid,cid).map(this::toDomain);
    }
    @Override @Transactional(readOnly=true)
    public List<Progression> findByApprenantId(UUID aid) {
        return repo.findByApprenantId(aid).stream().map(this::toDomain).collect(Collectors.toList());
    }
    @Override @Transactional
    public Progression save(Progression p) {
        return toDomain(repo.save(repo.findByApprenantIdAndCoursId(p.getApprenantId(),p.getCoursId())
            .map(e -> update(p,e)).orElseGet(() -> toEntity(p))));
    }
    @Override @Transactional
    public int activerPaiement(UUID aid, UUID cid) { return repo.activerPaiement(aid,cid); }

    private ProgressionJpaEntity update(Progression p, ProgressionJpaEntity e) {
        e.setPourcentage(p.getPourcentage()); e.setEstPaye(p.isEstPaye());
        e.setXpGagne(p.getXpGagne()); e.setDateCompletion(p.getDateCompletion()); return e;
    }
    private ProgressionJpaEntity toEntity(Progression p) {
        return ProgressionJpaEntity.builder().id(p.getId())
            .apprenantId(p.getApprenantId()).coursId(p.getCoursId())
            .pourcentage(p.getPourcentage()).estPaye(p.isEstPaye())
            .xpGagne(p.getXpGagne()).dateDebut(p.getDateDebut()!=null?p.getDateDebut():LocalDateTime.now())
            .dateCompletion(p.getDateCompletion())
            .seuilPaiementCours(0.30).build();
    }
    private Progression toDomain(ProgressionJpaEntity e) {
        return new Progression(e.getId(),e.getApprenantId(),e.getCoursId(),
            e.getPourcentage(),e.isEstPaye(),e.getXpGagne(),e.getDateDebut(),
            e.getDateCompletion(),e.getSeuilPaiementCours(),e.getCreatedAt(),e.getUpdatedAt());
    }
}
