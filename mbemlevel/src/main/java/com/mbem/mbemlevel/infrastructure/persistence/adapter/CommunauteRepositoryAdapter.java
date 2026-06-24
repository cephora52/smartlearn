package com.mbem.mbemlevel.infrastructure.persistence.adapter;
import com.mbem.mbemlevel.application.port.out.CommunauteRepository;
import com.mbem.mbemlevel.domain.communaute.MessageCommunaute;
import com.mbem.mbemlevel.infrastructure.persistence.entity.MessageCommunauteJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.MessageCommunauteJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
@Component @RequiredArgsConstructor
public class CommunauteRepositoryAdapter implements CommunauteRepository {
    private final MessageCommunauteJpaRepository repo;
    @Override @Transactional
    public MessageCommunaute save(MessageCommunaute m) { return toDomain(repo.save(toEntity(m))); }
    @Override @Transactional(readOnly=true)
    public Optional<MessageCommunaute> findById(UUID id) { return repo.findById(id).map(this::toDomain); }
    @Override @Transactional(readOnly=true)
    public Page<MessageCommunaute> findQuestions(UUID cid, Pageable p) {
        return repo.findQuestions(cid, p).map(this::toDomain);
    }
    @Override @Transactional(readOnly=true)
    public Page<MessageCommunaute> findReponses(UUID pid, Pageable p) {
        return repo.findReponses(pid, p).map(this::toDomain);
    }
    private MessageCommunaute toDomain(MessageCommunauteJpaEntity e) {
        return new MessageCommunaute(e.getId(),e.getCoursId(),e.getAuteurId(),e.getParentId(),
            e.getContenu(),e.isEstQuestion(),e.isEstResolu(),e.isEstModere(),e.getNbLikes(),
            e.getCreatedAt(),e.getUpdatedAt());
    }
    private MessageCommunauteJpaEntity toEntity(MessageCommunaute m) {
        return MessageCommunauteJpaEntity.builder()
            .id(m.getId()!=null?m.getId():UUID.randomUUID())
            .coursId(m.getCoursId()).auteurId(m.getAuteurId()).parentId(m.getParentId())
            .contenu(m.getContenu()).estQuestion(m.isEstQuestion())
            .estResolu(m.isEstResolu()).estModere(m.isEstModere())
            .nbLikes(m.getNbLikes()).build();
    }
}
