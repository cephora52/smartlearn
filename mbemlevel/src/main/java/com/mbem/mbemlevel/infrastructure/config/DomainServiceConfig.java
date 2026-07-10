package com.mbem.mbemlevel.infrastructure.config;

import com.mbem.mbemlevel.domain.cours.CoursDomainService;
import com.mbem.mbemlevel.domain.paiement.PaiementDomainService;
import com.mbem.mbemlevel.domain.session.SessionDomainService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DomainServiceConfig {

    @Bean
    public CoursDomainService coursDomainService() {
        return new CoursDomainService();
    }

    @Bean
    public PaiementDomainService paiementDomainService() {
        return new PaiementDomainService();
    }

    @Bean
    public SessionDomainService sessionDomainService() {
        return new SessionDomainService();
    }
}
