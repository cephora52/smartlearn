package com.mbem.mbemlevel.domain.certificat;
import com.mbem.mbemlevel.domain.progression.Progression;
/**
 * Règles d'obtention d'un certificat.
 * Un certificat est émis uniquement si :
 *   - Le cours est payé (accès complet activé)
 *   - La progression est à 100%
 */
public class CertificatDomainService {
    public boolean peutObtenirCertificat(Progression progression) {
        return progression.isEstPaye() && progression.estTermine();
    }
}
