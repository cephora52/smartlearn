package com.mbem.mbemlevel.application.usecase.communaute;
import com.mbem.mbemlevel.application.port.out.CommunauteRepository;
import com.mbem.mbemlevel.domain.communaute.MessageCommunaute;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/** S12 — Poster une question ou une réponse dans la communauté. */
@Service @RequiredArgsConstructor
public class PostMessageUseCase {
    private final CommunauteRepository repo;
    @Transactional
    public MessageCommunaute poster(UUID coursId, UUID auteurId,
                                    String contenu, UUID parentId) {
        MessageCommunaute m = (parentId == null)
            ? MessageCommunaute.poserQuestion(coursId, auteurId, contenu)
            : MessageCommunaute.repondre(coursId, auteurId, parentId, contenu);
        return repo.save(m);
    }
}
