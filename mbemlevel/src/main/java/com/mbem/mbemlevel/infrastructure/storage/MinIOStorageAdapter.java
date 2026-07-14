package com.mbem.mbemlevel.infrastructure.storage;
import com.mbem.mbemlevel.application.port.out.StoragePort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import jakarta.annotation.PostConstruct;
import java.time.Duration;
/**
 * Stockage S3-compatible (MinIO en dev, AWS S3 en prod).
 * Utilisé pour : CVs, certificats PDF, images de cours.
 */
@Component @RequiredArgsConstructor @Slf4j
public class MinIOStorageAdapter implements StoragePort {
    private final S3Client   s3Client;
    private final S3Presigner presigner;
    @Value("${storage.minio.bucket-name:${MINIO_BUCKET_NAME:mbemnova}}") private String bucket;
    private boolean bucketCree = false;

    @PostConstruct
    public void init() {
        assurerBucketExiste();
    }

    private synchronized void assurerBucketExiste() {
        if (bucketCree) return;
        try {
            s3Client.headBucket(HeadBucketRequest.builder().bucket(bucket).build());
            log.info("[STORAGE] Le bucket '{}' existe déjà.", bucket);
            bucketCree = true;
        } catch (NoSuchBucketException e) {
            creerBucket();
        } catch (S3Exception e) {
            if (e.statusCode() == 404) {
                creerBucket();
            } else {
                log.error("[STORAGE] Erreur S3 lors de la vérification du bucket '{}'", bucket, e);
            }
        } catch (Exception e) {
            log.error("[STORAGE] Erreur lors de la vérification du bucket '{}'", bucket, e);
        }
    }

    private void creerBucket() {
        try {
            log.info("[STORAGE] Le bucket '{}' n'existe pas. Création en cours...", bucket);
            s3Client.createBucket(CreateBucketRequest.builder().bucket(bucket).build());
            log.info("[STORAGE] Le bucket '{}' a été créé avec succès.", bucket);
            bucketCree = true;
        } catch (Exception e) {
            log.error("[STORAGE] Impossible de créer le bucket '{}'", bucket, e);
        }
    }

    @Override
    public String upload(String path, byte[] content, String contentType) {
        assurerBucketExiste();
        s3Client.putObject(
            PutObjectRequest.builder().bucket(bucket).key(path).contentType(contentType).build(),
            RequestBody.fromBytes(content));
        log.debug("[STORAGE] Uploadé: {}", path);
        return path;
    }
    @Override
    public void delete(String path) {
        assurerBucketExiste();
        s3Client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(path).build());
    }
    @Override
    public String presignedUrl(String path) {
        assurerBucketExiste();
        return presigner.presignGetObject(GetObjectPresignRequest.builder()
            .signatureDuration(Duration.ofHours(1))
            .getObjectRequest(GetObjectRequest.builder().bucket(bucket).key(path).build())
            .build()).url().toString();
    }
}
