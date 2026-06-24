package com.mbem.mbemlevel.infrastructure.pdf;
import com.mbem.mbemlevel.application.port.out.PDFPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import java.io.ByteArrayOutputStream;
import java.util.Map;
/**
 * Génère des PDFs depuis les templates Thymeleaf via iText 8 + html2pdf.
 * Utilisé pour : certificats PDF, factures, emplois du temps.
 */
@Component @RequiredArgsConstructor @Slf4j
public class ITextPDFAdapter implements PDFPort {
    private final TemplateEngine templateEngine;
    @Override
    public byte[] generer(String templateName, Map<String, Object> variables) {
        try {
            Context ctx = new Context(); ctx.setVariables(variables);
            String html = templateEngine.process("pdf/" + templateName, ctx);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            // Conversion HTML → PDF via iText html2pdf
            com.itextpdf.html2pdf.HtmlConverter.convertToPdf(html, baos);
            log.debug("[PDF] Généré: template={} size={}bytes", templateName, baos.size());
            return baos.toByteArray();
        } catch (Exception e) {
            log.error("[PDF] Erreur génération {}: {}", templateName, e.getMessage());
            throw new RuntimeException("Erreur génération PDF : " + templateName, e);
        }
    }
}
