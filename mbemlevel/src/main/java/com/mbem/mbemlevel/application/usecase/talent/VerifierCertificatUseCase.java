package com.mbem.mbemlevel.application.usecase.talent;
import com.mbem.mbemlevel.application.port.out.CertificatRepository;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Optional;
/** Vérification publique d'un certificat par code (recruteurs). */
@Service @RequiredArgsConstructor
public class VerifierCertificatUseCase {
    private final CertificatRepository repo;
    @Transactional(readOnly=true)
    public Optional<Certificat> executer(String code) { return repo.findByCode(code); }
}
