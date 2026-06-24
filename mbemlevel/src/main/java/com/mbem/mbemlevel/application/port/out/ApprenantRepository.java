package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.user.Apprenant;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ApprenantRepository {
    Optional<Apprenant> findById(UUID id);
    Optional<Apprenant> findByEmail(String email);
    boolean existsByEmail(String email);
    Apprenant save(Apprenant apprenant);
    List<Apprenant> findAll();
    List<Apprenant> findDisponiblesPourEmploi();
}
