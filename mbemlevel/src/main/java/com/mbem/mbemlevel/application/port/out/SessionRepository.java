package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.session.*;
import java.util.*;
public interface SessionRepository {
    Optional<Session>  findById(UUID id);
    List<Session>      findDisponibles(UUID coursId);
    Session            save(Session session);
    Optional<Devoir>   findDevoirById(UUID id);
    List<Devoir>       findDevoirsParSession(UUID sessionId);
    Devoir             saveDevoir(Devoir devoir);
    Optional<Rendu>    findRenduByDevoirAndApprenant(UUID devoirId, UUID apprenantId);
    List<Rendu>        findRendusParDevoir(UUID devoirId);
    Rendu              saveRendu(Rendu rendu);
}
