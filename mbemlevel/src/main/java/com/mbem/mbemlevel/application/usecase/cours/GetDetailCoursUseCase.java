package com.mbem.mbemlevel.application.usecase.cours;
import com.mbem.mbemlevel.application.port.out.CoursRepository;
import com.mbem.mbemlevel.domain.cours.Cours;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/** S04 — Détail d'un cours par ID ou slug. */
@Service @RequiredArgsConstructor
public class GetDetailCoursUseCase {
    private final CoursRepository coursRepo;
    @Transactional(readOnly=true)
    public Cours parId(UUID id) {
        return coursRepo.findById(id)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
    }
    @Transactional(readOnly=true)
    public Cours parSlug(String slug) {
        return coursRepo.findBySlug(slug)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
    }
}
