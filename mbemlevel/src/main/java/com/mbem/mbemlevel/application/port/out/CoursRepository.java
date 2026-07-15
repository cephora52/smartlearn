package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import org.springframework.data.domain.*;
import java.util.*;
public interface CoursRepository {
    Optional<Cours> findById(UUID id);
    Optional<Cours> findBySlug(String slug);
    Page<Cours>     findCatalogue(NiveauCours niveau, UUID categorieId, Pageable pageable);
    Cours           save(Cours cours);
    boolean         existsBySlug(String slug);
    long            count();
}
