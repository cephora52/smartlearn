package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import com.mbem.mbemlevel.infrastructure.storage.MediaUploadService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.Map;
import java.util.UUID;

/**
 * Upload des médias pour les cours — S19
 *
 * POST /api/v1/media/cours/{coursId}/banniere        → Bannière du cours
 * POST /api/v1/media/cours/{coursId}/images          → Image d'une leçon
 * POST /api/v1/media/cours/{coursId}/pdfs            → PDF d'une leçon
 * POST /api/v1/media/videos/valider                  → Valider un lien YouTube/Vimeo
 */
@RestController
@RequestMapping("/api/v1/media")
@Tag(name = "Upload Médias", description = "Upload images/PDFs pour les cours — S19")
@PreAuthorize("hasAnyRole('FORMATEUR','ADMIN','SUPER_ADMIN')")
@RequiredArgsConstructor
public class UploadMediaController {

    private final MediaUploadService uploadService;

    /**
     * Upload la bannière d'un cours (image de couverture).
     * Retourne 3 URLs : original, medium, thumbnail.
     * Formats acceptés : JPEG, PNG, WebP — max 10 Mo.
     */
    @PostMapping(value = "/cours/{coursId}/banniere",
                 consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload bannière de cours (S19)")
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadBanniere(
            @PathVariable UUID coursId,
            @RequestPart("fichier") MultipartFile fichier) {
        var result = uploadService.uploadBanniereCours(fichier, coursId);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(Map.of(
            "urlOriginal",   result.urlOriginal(),
            "urlMedium",     result.urlMedium(),
            "urlThumbnail",  result.urlThumbnail(),
            "tailleMo",      String.format("%.2f", result.tailleBytes() / (1024.0 * 1024.0))
        ), "Bannière uploadée et compressée."));
    }

    /**
     * Upload une image pour une leçon.
     * Génère automatiquement : original (max 1920px), medium (800px), thumbnail (400px).
     * Formats : JPEG, PNG, WebP — max 10 Mo.
     */
    @PostMapping(value = "/cours/{coursId}/images",
                 consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload image pour une leçon (S19)")
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadImage(
            @PathVariable UUID coursId,
            @RequestPart("fichier") MultipartFile fichier) {
        var result = uploadService.uploadImageLecon(fichier, coursId);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(Map.of(
            "urlOriginal",   result.urlOriginal(),
            "urlMedium",     result.urlMedium(),
            "urlThumbnail",  result.urlThumbnail()
        ), "Image compressée et uploadée. Utilisez urlMedium dans vos blocs de leçon."));
    }

    /**
     * Upload un PDF de leçon (support de cours, exercices).
     * Max 50 Mo — uniquement application/pdf.
     */
    @PostMapping(value = "/cours/{coursId}/pdfs",
                 consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload PDF pour une leçon (S19)")
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadPdf(
            @PathVariable UUID coursId,
            @RequestPart("fichier") MultipartFile fichier) {
        var result = uploadService.uploadPdfLecon(fichier, coursId);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(Map.of(
            "urlPdf",    result.urlStockage(),
            "nomPdf",    result.nomAffiche(),
            "tailleMo",  String.format("%.2f", result.tailleBytes() / (1024.0 * 1024.0))
        ), "PDF uploadé. Utilisez urlPdf dans un bloc PDF_EMBED."));
    }

    /**
     * Valide et normalise un lien vidéo YouTube ou Vimeo.
     * Retourne l'URL d'embed prête à utiliser dans un bloc VIDEO_YOUTUBE ou VIDEO_VIMEO.
     * MbemNova n'héberge pas les vidéos — embed uniquement.
     */
    @PostMapping("/videos/valider")
    @Operation(summary = "Valider un lien vidéo YouTube/Vimeo (S19)")
    public ResponseEntity<ApiResponse<Map<String, String>>> validerVideo(
            @RequestBody Map<String, String> body) {
        String url = body.get("url");
        String urlEmbed = uploadService.validerEtNormaliserLienVideo(url);
        String type = urlEmbed.contains("youtube") ? "VIDEO_YOUTUBE" : "VIDEO_VIMEO";
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
            "urlEmbed", urlEmbed,
            "typeBloc", type
        ), "Lien vidéo valide. Utilisez urlEmbed dans votre bloc " + type + "."));
    }
}
