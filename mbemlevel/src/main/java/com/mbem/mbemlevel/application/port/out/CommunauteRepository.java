package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.communaute.MessageCommunaute;
import org.springframework.data.domain.*;
import java.util.*;
public interface CommunauteRepository {
    MessageCommunaute          save(MessageCommunaute message);
    Optional<MessageCommunaute> findById(UUID id);
    Page<MessageCommunaute>    findQuestions(UUID coursId, Pageable pageable);
    Page<MessageCommunaute>    findReponses(UUID parentId, Pageable pageable);
}
