package com.mbem.mbemlevel.api.config;
import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
/**
 * Propriétés JWT lues depuis application.yaml.
 * Les valeurs prod viennent exclusivement des ENV VARS.
 */
@Component
@Getter
public class JwtConfig {
    @Value("${security.jwt.secret}")
    private String secret;
    @Value("${security.jwt.expiration-ms:86400000}")
    private long expirationMs;
    @Value("${security.jwt.refresh-expiration-ms:2592000000}")
    private long refreshExpirationMs;
    @Value("${security.jwt.token-prefix:Bearer }")
    private String tokenPrefix;
    @Value("${security.jwt.header-name:Authorization}")
    private String headerName;
}
