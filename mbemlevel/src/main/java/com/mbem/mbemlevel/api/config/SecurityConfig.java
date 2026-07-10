package com.mbem.mbemlevel.api.config;
import com.mbem.mbemlevel.api.filter.*;
import com.mbem.mbemlevel.api.security.*;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.*;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.*;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;
import org.springframework.web.cors.*;
import java.util.List;
/**
 * Spring Security 7 — Stateless JWT, CORS, CSRF off, headers sécurité.
 * Ordre filtres : RateLimit → SecurityHeaders → JWT → Spring Security.
 */
@Configuration @EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
@RequiredArgsConstructor
public class SecurityConfig {
    private final JwtAuthenticationFilter jwtFilter;
    private final RateLimitFilter         rateLimitFilter;
    private final SecurityHeadersFilter   headersFilter;
    private final RequestLoggingFilter    loggingFilter;
    private final UserDetailsService      userDetailsService;
    private final CustomAuthEntryPoint    authEntryPoint;
    private final CustomAccessDeniedHandler accessDeniedHandler;
    private final PasswordEncoder   passwordEncoder; 

    

    private static final String[] PUBLIC = {
        "/api/v1/auth/**", "/api/v1/cours", "/api/v1/cours/{id}",
        "/api/v1/categories", "/api/v1/talents", "/api/v1/certificats/verify/**",
        "/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html", "/actuator/health"
    };

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(c -> c.configurationSource(corsSource()))
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a
                .requestMatchers(PUBLIC).permitAll()
                .requestMatchers(HttpMethod.GET, "/api/v1/cours/**").permitAll()
                .requestMatchers("/api/v1/admin/cours", "/api/admin/cours", "/api/v1/admin/cours/**", "/api/admin/cours/**")
                    .hasAnyRole("FORMATEUR", "ADMIN", "SUPER_ADMIN")
                .requestMatchers("/api/v1/admin/**", "/api/admin/**").hasAnyRole("ADMIN","SUPER_ADMIN")
                .requestMatchers("/api/v1/formateur/**", "/api/formateur/**").hasRole("FORMATEUR")
                .requestMatchers("/api/v1/apprenant/**", "/api/apprenant/**").hasRole("APPRENANT")
                .requestMatchers(HttpMethod.POST, "/api/v1/cours/**")
                    .hasAnyRole("FORMATEUR","ADMIN","SUPER_ADMIN")
                .anyRequest().authenticated())
            .exceptionHandling(e -> e
                .authenticationEntryPoint(authEntryPoint)
                .accessDeniedHandler(accessDeniedHandler))
            .headers(h -> h
                .httpStrictTransportSecurity(s -> s.maxAgeInSeconds(31_536_000).includeSubDomains(true))
                .frameOptions(f -> f.deny())
                .contentSecurityPolicy(c -> c.policyDirectives(
                    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; " +
                    "img-src 'self' data: https:; frame-ancestors 'none'"))
                .contentTypeOptions(c -> {})
                .referrerPolicy(r -> r.policy(
                    ReferrerPolicyHeaderWriter.ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN)))
            .authenticationProvider(authProvider())
            .addFilterBefore(loggingFilter,    UsernamePasswordAuthenticationFilter.class)
            .addFilterBefore(rateLimitFilter,  UsernamePasswordAuthenticationFilter.class)
            .addFilterBefore(headersFilter,    UsernamePasswordAuthenticationFilter.class)
            .addFilterBefore(jwtFilter,        UsernamePasswordAuthenticationFilter.class)
            .build();
    }

    // @Bean
    // public PasswordEncoder passwordEncoder() {
    //     return new BCryptPasswordEncoder(12);
    // }

        @Bean
    public AuthenticationProvider authProvider() {
        var p = new DaoAuthenticationProvider(userDetailsService);
        p.setPasswordEncoder(passwordEncoder); // ← Utilise le bean injecté
        return p;
    }

    @Bean
    public AuthenticationManager authManager(AuthenticationConfiguration c) throws Exception {
        return c.getAuthenticationManager();
    }

    @Bean
    public CorsConfigurationSource corsSource() {
        var cfg = new CorsConfiguration();
        cfg.setAllowedOriginPatterns(List.of(
            "http://localhost:4200", "http://localhost:4000",
            "http://localhost:3000", "http://localhost:5173",
            "https://mbemnova.com","https://www.mbemnova.com","https://app.mbemnova.com"));
        cfg.setAllowedMethods(List.of("GET","POST","PUT","PATCH","DELETE","OPTIONS"));
        cfg.setAllowedHeaders(List.of("Authorization","Content-Type","Accept","X-Request-ID"));
        cfg.setAllowCredentials(true);
        cfg.setMaxAge(3600L);
        var src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/**", cfg);
        return src;
    }
}
