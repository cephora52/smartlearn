package com.mbem.mbemlevel.api.config;
 
import org.springframework.boot.security.autoconfigure.actuate.web.servlet.EndpointRequest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
/** Sécurise les endpoints Actuator : /actuator/prometheus public, reste SUPER_ADMIN. */
@Configuration
public class ActuatorSecurityConfig {
    @Bean
    @Order(1)
    public SecurityFilterChain actuatorFilterChain(HttpSecurity http) throws Exception {
        return http
            .securityMatcher(EndpointRequest.toAnyEndpoint())
            .authorizeHttpRequests(a -> a
                .requestMatchers(EndpointRequest.to("health", "prometheus")).permitAll()
                .anyRequest().hasRole("SUPER_ADMIN"))
            .build();
    }
}
