package com.mbem.mbemlevel.application.port.out;
import java.util.Map;
/** Port sortant — génération PDF (certificats, factures). Implémenté par ITextPDFAdapter. */
public interface PDFPort {
    /** Génère un PDF depuis un template Thymeleaf et retourne les bytes. */
    byte[] generer(String templateName, Map<String, Object> variables);
}
