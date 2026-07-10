package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.SessionRepository;
import com.mbem.mbemlevel.domain.session.*;
import com.mbem.mbemlevel.domain.shared.enums.Modalite;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class SessionRepositoryAdapter implements SessionRepository {
    private final SessionJpaRepository sessionRepo;
    private final DevoirJpaRepository devoirRepo;
    private final RenduJpaRepository renduRepo;

    @Override
    @Transactional(readOnly = true)
    public Optional<Session> findById(UUID id) {
        return sessionRepo.findById(id).map(this::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Session> findDisponibles(UUID coursId) {
        return sessionRepo.findSessionsDisponibles(coursId).stream().map(this::toDomain).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public Session save(Session s) {
        return toDomain(sessionRepo.save(sessionRepo.findById(s.getId())
                .map(e -> updateSession(s, e)).orElseGet(() -> toSessionEntity(s))));
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Devoir> findDevoirById(UUID id) {
        return devoirRepo.findById(id).map(this::toDevoirDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Devoir> findDevoirsParSession(UUID sid) {
        return devoirRepo.findBySessionIdAndEstVerrouilleIsFalse(sid).stream().map(this::toDevoirDomain)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public Devoir saveDevoir(Devoir d) {
        return toDevoirDomain(devoirRepo.save(toDevoirEntity(d)));
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Rendu> findRenduByDevoirAndApprenant(UUID did, UUID aid) {
        return renduRepo.findByDevoirIdAndApprenantId(did, aid).map(this::toRenduDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Rendu> findRendusParDevoir(UUID did) {
        return renduRepo.findByDevoirId(did).stream().map(this::toRenduDomain).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public Rendu saveRendu(Rendu r) {
        RenduJpaEntity e = renduRepo.findByDevoirIdAndApprenantId(r.getDevoirId(), r.getApprenantId())
                .map(ex -> updateRendu(r, ex)).orElseGet(() -> toRenduEntity(r));
        return toRenduDomain(renduRepo.save(e));
    }

    // ── Mappers ───────────────────────────────────────────────────────────────
// toDomain() ligne 82 — String → Enum
private Session toDomain(SessionJpaEntity e) {
    return new Session(e.getId(), e.getCoursId(), e.getFormateurId(), e.getTitre(),
            Modalite.valueOf(e.getModalite()),
            e.getDateDebut().toLocalDate(),   // ← LocalDateTime → LocalDate
            e.getDateFin().toLocalDate(),      // ← LocalDateTime → LocalDate
            e.getCapaciteMax(), e.getNbInscrits(),
            e.getLienReunion(), e.getLieu(), e.isEstActive(),
            e.getCreatedAt(), e.getUpdatedAt());
}

private SessionJpaEntity toSessionEntity(Session s) {
    return SessionJpaEntity.builder()
            .id(s.getId() != null ? s.getId() : UUID.randomUUID())
            .coursId(s.getCoursId()).formateurId(s.getFormateurId()).titre(s.getTitre())
            .modalite(s.getModalite().name())
            .dateDebut(s.getDateDebut().atStartOfDay())  // ← LocalDate → LocalDateTime
            .dateFin(s.getDateFin().atStartOfDay())       // ← LocalDate → LocalDateTime
            .capaciteMax(s.getCapaciteMax()).nbInscrits(s.getNbInscrits())
            .lienReunion(s.getLienReunion()).lieu(s.getLieu()).estActive(s.isEstActive()).build();
}

    private SessionJpaEntity updateSession(Session s, SessionJpaEntity e) {
        e.setNbInscrits(s.getNbInscrits());
        e.setEstActive(s.isEstActive());
        e.setLienReunion(s.getLienReunion());
        return e;
    }

    private Devoir toDevoirDomain(DevoirJpaEntity e) {
        return new Devoir(e.getId(), e.getSessionId(), e.getModuleId(), e.getTitre(),
                e.getConsignes(), e.getDateRemise(), e.isEstVerrouille(),
                e.getLienRessources(), e.getCreatedAt(), e.getUpdatedAt());
    }

    private DevoirJpaEntity toDevoirEntity(Devoir d) {
        return DevoirJpaEntity.builder().id(d.getId() != null ? d.getId() : UUID.randomUUID())
                .sessionId(d.getSessionId()).moduleId(d.getModuleId()).titre(d.getTitre())
                .consignes(d.getConsignes()).dateRemise(d.getDateRemise())
                .estVerrouille(d.isEstVerrouille()).lienRessources(d.getLienRessources()).build();
    }

    private Rendu toRenduDomain(RenduJpaEntity e) {
        return new Rendu(e.getId(), e.getDevoirId(), e.getApprenantId(), e.getContenu(),
                e.getLienFichier(), e.getNote(), e.getCommentaire(), e.getDateSoumission(),
                e.getDateCorrection(), e.isEnRetard(), e.getCreatedAt(), e.getUpdatedAt());
    }

    private RenduJpaEntity toRenduEntity(Rendu r) {
        return RenduJpaEntity.builder().id(r.getId() != null ? r.getId() : UUID.randomUUID())
                .devoirId(r.getDevoirId()).apprenantId(r.getApprenantId())
                .contenu(r.getContenu()).lienFichier(r.getLienFichier())
                .dateSoumission(r.getDateSoumission()).build();
    }

    private RenduJpaEntity updateRendu(Rendu r, RenduJpaEntity e) {
        e.setNote(r.getNote());
        e.setCommentaire(r.getCommentaire());
        e.setDateCorrection(r.getDateCorrection());
        return e;
    }
}
