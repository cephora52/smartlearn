package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.progression.Progression;
import java.util.*;
public interface ProgressionRepository {
    Optional<Progression> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<Progression>     findByApprenantId(UUID apprenantId);
    Progression           save(Progression progression);
    int                   activerPaiement(UUID apprenantId, UUID coursId);
}
