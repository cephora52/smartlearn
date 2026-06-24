package com.mbem.mbemlevel.api.config;
import com.mbem.mbemlevel.domain.certificat.CertificatDomainService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.time.Clock;
/**
 * Beans partagés de l'application.
 * BCrypt cost=12 : ~300ms/hash — bon compromis sécurité/UX.
 */
@Configuration
public class ApplicationConfig {
    @Bean
    public PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(12); }
    @Bean
    public Clock clock() { return Clock.systemDefaultZone(); }
    @Bean
    public CertificatDomainService certificatDomainService() {
        return new CertificatDomainService();
    }
}
