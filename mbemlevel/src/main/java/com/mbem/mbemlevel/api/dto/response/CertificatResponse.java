package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.certificat.Certificat;
import java.time.LocalDateTime;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record CertificatResponse(
    UUID id, UUID coursId, String codeVerification,
    String lienPdf, LocalDateTime dateEmission
) {
    public static CertificatResponse from(Certificat c) {
        return new CertificatResponse(c.getId(), c.getCoursId(),
            c.getCodeVerification(), c.getLienPdf(), c.getDateEmission());
    }

    public static CertificatResponse from(Certificat c, boolean estPaye) {
        return new CertificatResponse(c.getId(), c.getCoursId(),
            c.getCodeVerification(), estPaye ? c.getLienPdf() : null, c.getDateEmission());
    }
}
