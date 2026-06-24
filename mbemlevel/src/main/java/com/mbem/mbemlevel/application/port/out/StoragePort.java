package com.mbem.mbemlevel.application.port.out;
/** Port sortant — stockage S3/MinIO (CV, certificats PDF, images). */
public interface StoragePort {
    /** Upload un fichier et retourne son URL publique. */
    String upload(String bucketPath, byte[] content, String contentType);
    /** Supprime un fichier. */
    void   delete(String bucketPath);
    /** Génère une URL présignée temporaire (60 min). */
    String presignedUrl(String bucketPath);
}
