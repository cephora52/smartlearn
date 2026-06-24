package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import java.util.List;
@Component @RequiredArgsConstructor
public class UtilisateurListAdapter {
    private final UtilisateurRepository repo;
    public List<Utilisateur> findDisponibles() { return repo.findApprenantsDisponibles(); }
}
