package com.mbem.mbemlevel.application.usecase.progression;
import com.mbem.mbemlevel.application.port.out.ProgressionRepository;
import com.mbem.mbemlevel.domain.progression.Progression;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
@Service @RequiredArgsConstructor
public class GetProgressionUseCase {
    private final ProgressionRepository repo;
    @Transactional(readOnly=true)
    public Optional<Progression> parCoursId(UUID apprenantId, UUID coursId) {
        return repo.findByApprenantIdAndCoursId(apprenantId, coursId);
    }
    @Transactional(readOnly=true)
    public List<Progression> toutesParApprenant(UUID apprenantId) {
        return repo.findByApprenantId(apprenantId);
    }
}
