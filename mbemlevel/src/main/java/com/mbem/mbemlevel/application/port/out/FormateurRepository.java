package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.user.Formateur;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FormateurRepository {
    Optional<Formateur> findById(UUID id);
    Optional<Formateur> findByEmail(String email);
    boolean existsByEmail(String email);
    Formateur save(Formateur formateur);
    List<Formateur> findAll();
}
