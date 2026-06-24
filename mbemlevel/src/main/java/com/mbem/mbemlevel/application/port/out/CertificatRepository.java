package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import java.util.*;
public interface CertificatRepository {
    Optional<Certificat> findById(UUID id);
    Optional<Certificat> findByCode(String codeVerification);
    Optional<Certificat> findByApprenantAndCours(UUID apprenantId, UUID coursId);
    List<Certificat>     findByApprenant(UUID apprenantId);
    Certificat           save(Certificat certificat);
}
