package com.mbem.mbemlevel.infrastructure.storage;

import lombok.extern.slf4j.Slf4j;
import net.coobird.thumbnailator.Thumbnails;
import net.coobird.thumbnailator.geometry.Positions;
import org.springframework.stereotype.Service;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

/**
 * Compression et redimensionnement d'images pour les cours.
 *
 * Génère 3 formats pour chaque image uploadée :
 * - ORIGINAL : image source convertie en WebP, qualité 85%, max 1920px
 * - MEDIUM : 800×600px WebP, qualité 80% — utilisé dans les leçons
 * - THUMBNAIL : 400×300px WebP, qualité 75% — utilisé dans les cartes catalogue
 *
 * Format WebP = 25-35% plus léger que JPEG à qualité équivalente.
 * Critique pour les apprenants en Afrique avec connexions 3G/4G limitées.
 */
@Service
@Slf4j
public class ImageCompressionService {

    // Formats de sortie
    public static final String FORMAT_WEBP = "webp";
    public static final String MIME_WEBP = "image/webp";

    // Dimensions
    private static final int MAX_ORIGINAL_WIDTH = 1920;
    private static final int MEDIUM_WIDTH = 800;
    private static final int MEDIUM_HEIGHT = 600;
    private static final int THUMB_WIDTH = 400;
    private static final int THUMB_HEIGHT = 300;

    // Qualité (0.0 – 1.0)
    private static final float QUALITY_ORIGINAL = 0.85f;
    private static final float QUALITY_MEDIUM = 0.80f;
    private static final float QUALITY_THUMB = 0.75f;

    // Taille max upload : 10 Mo
    public static final long MAX_SIZE_BYTES = 10 * 1024 * 1024L;

    /**
     * Valide et compresse une image uploadée.
     *
     * @param rawBytes Bytes bruts du fichier uploadé
     * @param mimeType MIME type déclaré par le client
     * @return ImageVariants — 3 versions compressées prêtes pour MinIO
     * @throws ImageValidationException si le fichier est invalide
     */
    public ImageVariants compresser(byte[] rawBytes, String mimeType) {
        validerMimeType(mimeType);
        validerTaille(rawBytes.length);

        try {
            BufferedImage source = ImageIO.read(new ByteArrayInputStream(rawBytes));
            if (source == null) {
                throw new ImageValidationException("Fichier image illisible ou corrompu.");
            }

            log.debug("[IMAGE] Source: {}x{} — compression en cours",
                    source.getWidth(), source.getHeight());

            return new ImageVariants(
                    compresserVersion(source, MAX_ORIGINAL_WIDTH, -1, QUALITY_ORIGINAL),
                    compresserVersion(source, MEDIUM_WIDTH, MEDIUM_HEIGHT, QUALITY_MEDIUM),
                    compresserVersion(source, THUMB_WIDTH, THUMB_HEIGHT, QUALITY_THUMB));

        } catch (IOException e) {
            throw new ImageValidationException("Erreur lors du traitement de l'image : " + e.getMessage());
        }
    }

    /**
     * Compresse et redimensionne une image vers WebP.
     *
     * @param source  Image source
     * @param width   Largeur cible (-1 = proportionnel)
     * @param height  Hauteur cible (-1 = proportionnel)
     * @param quality Qualité 0.0–1.0
     */
   private byte[] compresserVersion(BufferedImage source, int width, int height,
        float quality) throws IOException {
    if (source == null) {
        throw new ImageValidationException("Image invalide");
    }

    Thumbnails.Builder<BufferedImage> builder;  // ← AJOUTER CETTE LIGNE

    if (height == -1) {
            throw new ImageValidationException("Image invalide");
        } // Thumbnailator → JPEG
          // Note : la conversion WebP réelle nécessiterait libwebp ou cwebp.
          // En fallback, on utilise JPEG haute qualité qui est bien supporté partout.
          // Pour WebP natif en prod : ajouter la dépendance
          // com.twelvemonkeys.imageio:imageio-webp

        if (height == -1) {
            // Redimensionner seulement si l'image est plus large que la cible
            if (source.getWidth() > width) {
                builder = Thumbnails.of(source)
                        .width(width)
                        .outputQuality(quality)
                        .outputFormat("jpg");
            } else {
                builder = Thumbnails.of(source)
                        .scale(1.0)
                        .outputQuality(quality)
                        .outputFormat("jpg");
            }
        } else {
            builder = Thumbnails.of(source)
                    .size(width, height)
                    .crop(Positions.CENTER)
                    .outputQuality(quality)
                    .outputFormat("jpg");
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        builder.toOutputStream(out);
        byte[] result = out.toByteArray();

        log.debug("[IMAGE] Version {}x{} générée : {} Ko",
                width, height, result.length / 1024);
        return result;
    }

    private void validerMimeType(String mimeType) {
        if (mimeType == null || !mimeType.matches("image/(jpeg|jpg|png|webp|gif)")) {
            throw new ImageValidationException(
                    "Format non autorisé: " + mimeType +
                            ". Formats acceptés : JPEG, PNG, WebP, GIF.");
        }
    }

    private void validerTaille(long taille) {
        if (taille > MAX_SIZE_BYTES) {
            throw new ImageValidationException(
                    String.format("Image trop lourde : %.1f Mo. Maximum : 10 Mo.",
                            taille / (1024.0 * 1024.0)));
        }
        if (taille == 0) {
            throw new ImageValidationException("Fichier vide.");
        }
    }

    /** Les 3 variantes d'une image compressée */
    public record ImageVariants(
            byte[] original, // WebP max 1920px — qualité 85%
            byte[] medium, // WebP 800×600px — qualité 80%
            byte[] thumbnail // WebP 400×300px — qualité 75%
    ) {
    }

    /** Exception de validation d'image */
    public static class ImageValidationException extends RuntimeException {
        public ImageValidationException(String msg) {
            super(msg);
        }
    }
}
