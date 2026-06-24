package com.mbem.mbemlevel.application.usecase.session;
import com.mbem.mbemlevel.application.port.out.SessionRepository;
import com.mbem.mbemlevel.domain.session.Session;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;
/** S10 — Lister les sessions disponibles pour un cours. */
@Service @RequiredArgsConstructor
public class GetSessionsDisponiblesUseCase {
    private final SessionRepository repo;
    @Transactional(readOnly=true)
    public List<Session> executer(UUID coursId) { return repo.findDisponibles(coursId); }
}
