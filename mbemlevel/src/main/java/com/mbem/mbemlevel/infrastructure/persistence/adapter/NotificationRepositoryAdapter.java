package com.mbem.mbemlevel.infrastructure.persistence.adapter;
import com.mbem.mbemlevel.application.port.out.NotificationRepository;
import com.mbem.mbemlevel.domain.notification.Notification;
import com.mbem.mbemlevel.infrastructure.persistence.entity.NotificationJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.NotificationJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.stream.Collectors;
@Component @RequiredArgsConstructor
public class NotificationRepositoryAdapter implements NotificationRepository {
    private final NotificationJpaRepository repo;
    @Override @Transactional
    public Notification save(Notification n) { return toDomain(repo.save(toEntity(n))); }
    @Override @Transactional(readOnly=true)
    public List<Notification> findByUtilisateur(UUID uid) {
        return repo.findByUtilisateurIdOrderByCreatedAtDesc(uid)
            .stream().map(this::toDomain).collect(Collectors.toList());
    }
    @Override @Transactional(readOnly=true)
    public List<Notification> findNonLues(UUID uid) {
        return repo.findNonLues(uid).stream().map(this::toDomain).collect(Collectors.toList());
    }
    @Override @Transactional
    public int marquerToutesLues(UUID uid) { return repo.marquerToutesLues(uid); }
    @Override @Transactional(readOnly=true)
    public Optional<Notification> findById(UUID id) { return repo.findById(id).map(this::toDomain); }
    private Notification toDomain(NotificationJpaEntity e) {
        return new Notification(e.getId(),e.getUtilisateurId(),e.getTypeNotif(),
            e.getCanal(),e.getTitre(),e.getContenu(),e.isEstLue(),e.getDateLecture(),
            e.getLienAction(),e.getCreatedAt(),e.getUpdatedAt());
    }
    private NotificationJpaEntity toEntity(Notification n) {
        return NotificationJpaEntity.builder().id(n.getId())
            .utilisateurId(n.getUtilisateurId()).typeNotif(n.getTypeNotif())
            .canal(n.getCanal()).titre(n.getTitre()).contenu(n.getContenu())
            .estLue(n.isEstLue()).dateLecture(n.getDateLecture())
            .lienAction(n.getLienAction()).build();
    }
}
