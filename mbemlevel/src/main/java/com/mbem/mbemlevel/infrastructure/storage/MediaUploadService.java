package com.mbem.mbemlevel.infrastructure.storage;

import com.mbem.mbemlevel.application.port.out.StoragePort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.*;

/**
 * Service d'upload des médias pédagogiques.
 *
 * Gère les 3 types de médias utilisés dans les leçons :
 *   1. IMAGES  → compression WebP 3 formats, stockage MinIO
 *   2. PDFs    → validation MIME + taille, stockage MinIO
 *   3. VIDÉOS  → PAS d'hébergement direct (bande passante trop coûteuse)
 *               → L'instructeur fournit un lien YouTube/Vimeo
 *
 * Structure MinIO :
 *   cours/{coursId}/images/original/{uuid}.jpg
 *   cours/{coursId}/images/medium/{uuid}.jpg
 *   cours/{coursId}/images/thumbnail/{uuid}.jpg
 *   cours/{coursId}/pdfs/{uuid}-{nom-original}.pdf
 *   cours/{coursId}/banniere/original/{uuid}.jpg
 *   cours/{coursId}/banniere/thumbnail/{uuid}.jpg
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MediaUploadService {

    private final StoragePort             storagePort;
    private final ImageCompressionService imageCompressor;

    // Taille max PDF : 50 Mo
    private static final long MAX_PDF_SIZE = 50 * 1024 * 1024L;

    // Types MIME PDF autorisés
    private static final Set<String> MIME_PDF = Set.of("application/pdf");

    // ==========================================================================
    // UPLOAD IMAGE DE LEÇON
    // ==========================================================================

    /**
     * Upload une image de leçon.
     * Génère 3 variantes : original, medium (800px), thumbnail (400px).
     *
     * @return URLs des 3 variantes
     */
    public UploadImageResult uploadImageLecon(MultipartFile file, UUID coursId) {
        validerFichierNonVide(file);
        byte[] bytes = lireBytes(file);

        // Compresser en 3 formats
        ImageCompressionService.ImageVariants variants =
            imageCompressor.compresser(bytes, file.getContentType());

        String uuid = UUID.randomUUID().toString();
        String base = "cours/" + coursId + "/images";

        String urlOriginal   = storagePort.upload(base + "/original/"   + uuid + ".jpg", variants.original(),   "image/jpeg");
        String urlMedium     = storagePort.upload(base + "/medium/"     + uuid + ".jpg", variants.medium(),     "image/jpeg");
        String urlThumbnail  = storagePort.upload(base + "/thumbnail/"  + uuid + ".jpg", variants.thumbnail(),  "image/jpeg");

        log.info("[MEDIA] Image leçon uploadée — original:{}Ko medium:{}Ko thumb:{}Ko",
            variants.original().length / 1024,
            variants.medium().length / 1024,
            variants.thumbnail().length / 1024);

        return new UploadImageResult(urlOriginal, urlMedium, urlThumbnail,
            file.getOriginalFilename(), file.getSize());
    }

    /**
     * Upload la bannière d'un cours (image de couverture).
     * Format : 1200×630px (ratio 16:9) — optimisé pour partage réseaux sociaux.
     */
    public UploadImageResult uploadBanniereCours(MultipartFile file, UUID coursId) {
        validerFichierNonVide(file);
        byte[] bytes = lireBytes(file);

        ImageCompressionService.ImageVariants variants =
            imageCompressor.compresser(bytes, file.getContentType());

        String uuid = UUID.randomUUID().toString();
        String base = "cours/" + coursId + "/banniere";

        String urlOriginal  = storagePort.upload(base + "/original/"  + uuid + ".jpg", variants.original(),  "image/jpeg");
        String urlThumbnail = storagePort.upload(base + "/thumbnail/" + uuid + ".jpg", variants.thumbnail(), "image/jpeg");

        log.info("[MEDIA] Bannière cours {} uploadée", coursId);
        return new UploadImageResult(urlOriginal, urlThumbnail, urlThumbnail,
            file.getOriginalFilename(), file.getSize());
    }

    // ==========================================================================
    // UPLOAD PDF
    // ==========================================================================

    /**
     * Upload un PDF de leçon (support de cours, exercices, ressources).
     *
     * Validations :
     *  - MIME type doit être application/pdf
     *  - Taille max 50 Mo
     *  - Extension doit être .pdf
     *
     * @return URL MinIO du PDF
     */
    public UploadPdfResult uploadPdfLecon(MultipartFile file, UUID coursId) {
        validerFichierNonVide(file);
        validerMimePdf(file);
        validerTaillePdf(file.getSize());
        validerExtensionPdf(file.getOriginalFilename());

        byte[] bytes = lireBytes(file);
        String uuid = UUID.randomUUID().toString();
        String nomSanitise = sanitiserNomFichier(file.getOriginalFilename());
        String path = "cours/" + coursId + "/pdfs/" + uuid + "-" + nomSanitise;

        String url = storagePort.upload(path, bytes, "application/pdf");

        log.info("[MEDIA] PDF uploadé: {} ({}Ko) → {}", nomSanitise, bytes.length / 1024, url);
        return new UploadPdfResult(url, nomSanitise, file.getSize());
    }

    // ==========================================================================
    // VALIDATION LIEN VIDÉO
    // ==========================================================================

    /**
     * Valide un lien vidéo YouTube ou Vimeo.
     * MbemNova n'héberge PAS les vidéos — embed uniquement.
     *
     * @param url Lien fourni par le formateur
     * @return URL d'embed sécurisée
     */
    public String validerEtNormaliserLienVideo(String url) {
        if (url == null || url.isBlank()) {
            throw new IllegalArgumentException("Lien vidéo vide.");
        }

        // YouTube : https://www.youtube.com/watch?v=ID ou https://youtu.be/ID
        if (url.contains("youtube.com/watch?v=")) {
            String id = url.split("v=")[1].split("&")[0];
            return "https://www.youtube.com/embed/" + id;
        }
        if (url.contains("youtu.be/")) {
            String id = url.split("youtu.be/")[1].split("\\?")[0];
            return "https://www.youtube.com/embed/" + id;
        }

        // Vimeo : https://vimeo.com/ID
        if (url.contains("vimeo.com/")) {
            String id = url.split("vimeo.com/")[1].split("\\?")[0];
            return "https://player.vimeo.com/video/" + id;
        }

        throw new IllegalArgumentException(
            "URL vidéo non supportée. Utilisez YouTube ou Vimeo. URL reçue : " + url);
    }

    // ==========================================================================
    // HELPERS
    // ==========================================================================

    private void validerFichierNonVide(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Fichier vide.");
        }
    }

    private void validerMimePdf(MultipartFile file) {
        if (!MIME_PDF.contains(file.getContentType())) {
            throw new IllegalArgumentException(
                "Format non autorisé: " + file.getContentType() + ". Seul PDF est accepté.");
        }
    }

    private void validerTaillePdf(long taille) {
        if (taille > MAX_PDF_SIZE) {
            throw new IllegalArgumentException(
                String.format("PDF trop lourd : %.1f Mo. Maximum : 50 Mo.", taille / (1024.0 * 1024.0)));
        }
    }

    private void validerExtensionPdf(String nom) {
        if (nom == null || !nom.toLowerCase().endsWith(".pdf")) {
            throw new IllegalArgumentException("Extension invalide — seuls les fichiers .pdf sont acceptés.");
        }
    }

    private String sanitiserNomFichier(String nom) {
        if (nom == null) return "fichier.pdf";
        // Supprimer caractères dangereux pour les paths
        return nom.replaceAll("[^a-zA-Z0-9._-]", "_").toLowerCase();
    }

    private byte[] lireBytes(MultipartFile file) {
        try {
            return file.getBytes();
        } catch (IOException e) {
            throw new RuntimeException("Impossible de lire le fichier : " + e.getMessage());
        }
    }

    // ==========================================================================
    // RECORDS DE RÉSULTAT
    // ==========================================================================

    public record UploadImageResult(
        String urlOriginal,
        String urlMedium,
        String urlThumbnail,
        String nomOriginal,
        long   tailleBytes
    ) {}

    public record UploadPdfResult(
        String urlStockage,
        String nomAffiche,
        long   tailleBytes
    ) {}
}
