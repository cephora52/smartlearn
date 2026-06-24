package com.mbem.mbemlevel.infrastructure.config;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
import software.amazon.awssdk.auth.credentials.*;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import java.net.URI;
/**
 * Configuration AWS SDK S3 / MinIO.
 * En dev : MinIO local (http://localhost:9000).
 * En prod : AWS S3 ou MinIO distant avec TLS.
 */
@Configuration
public class StorageConfig {
    @Value("${storage.minio.endpoint:http://localhost:9000}") private String endpoint;
    @Value("${storage.minio.access-key:minioadmin}")          private String accessKey;
    @Value("${storage.minio.secret-key:minioadmin}")          private String secretKey;
    @Value("${storage.minio.region:af-central-1}")            private String region;

    private AwsCredentialsProvider credentials() {
        return StaticCredentialsProvider.create(
            AwsBasicCredentials.create(accessKey, secretKey));
    }

    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
            .endpointOverride(URI.create(endpoint))
            .credentialsProvider(credentials())
            .region(Region.of(region))
            .serviceConfiguration(S3Configuration.builder()
                .pathStyleAccessEnabled(true).build())
            .build();
    }

    @Bean
    public S3Presigner s3Presigner() {
        return S3Presigner.builder()
            .endpointOverride(URI.create(endpoint))
            .credentialsProvider(credentials())
            .region(Region.of(region))
            .build();
    }
}
