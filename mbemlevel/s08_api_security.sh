#!/usr/bin/env bash
# =============================================================================
# MbemNova · Script 08/15 · API Layer — Sécurité + Auth Controller
# =============================================================================
# CONTENU :
#   SecurityConfig · JwtConfig · ApplicationConfig · OpenApiConfig
#   RateLimitConfig · WebConfig · ActuatorSecurityConfig
#   JwtAuthenticationFilter · RateLimitFilter
#   RequestLoggingFilter · SecurityHeadersFilter
#   UserDetailsServiceImpl · CustomAuthEntryPoint · CustomAccessDeniedHandler
#   ApiResponse · PageResponse · ErrorResponse · AuthResponse
#   Toutes les Request DTOs auth · GlobalExceptionHandler + exceptions
#   AuthController (POST register/login/logout/refresh/reset-password/new-password)
#   AuditTrailAspect · PerformanceAspect
# PRÉREQUIS : s01-s07
# =============================================================================

set -euo pipefail; export LC_ALL=C.UTF-8
C_G='\033[0;32m'; C_C='\033[0;36m'; C_B='\033[1m'; NC='\033[0m'
ok()  { echo -e "${C_G}  [OK]${NC} $1"; }
sec() { echo -e "\n${C_B}${C_C}── $1 ──${NC}"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
[[ ! -f "$ROOT/pom.xml" ]] && { echo "ERR: s01 requis"; exit 1; }

echo -e "\n${C_B}${C_C}  MbemNova · 08/15 · API Security + Auth${NC}\n"

# =============================================================================
sec "1/5 Configuration API"
# =============================================================================
mkdir -p "$P/api/config"

cat > "$P/api/config/ApplicationConfig.java" << 'JEOF'
package com.mbem.mbemlevel.api.config;
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
}
JEOF

cat > "$P/api/config/JwtConfig.java" << 'JEOF'
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
JEOF

cat > "$P/api/config/WebConfig.java" << 'JEOF'
package com.mbem.mbemlevel.api.config;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
/** Compression GZIP activée dans application.yaml. Config MVC supplémentaire ici. */
@Configuration
@EnableWebMvc
public class WebConfig implements WebMvcConfigurer { }
JEOF

cat > "$P/api/config/OpenApiConfig.java" << 'JEOF'
package com.mbem.mbemlevel.api.config;
import io.swagger.v3.oas.models.*;
import io.swagger.v3.oas.models.info.*;
import io.swagger.v3.oas.models.security.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
/**
 * Configuration Swagger UI avec authentification JWT Bearer.
 * Désactivé en production via application-prod.yaml.
 */
@Configuration
public class OpenApiConfig {
    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("MbemNova API")
                .version("1.0.0")
                .description("Plateforme EdTech — Formation tech Afrique Centrale")
                .contact(new Contact().email("dev@mbemnova.com")))
            .addSecurityItem(new SecurityRequirement().addList("Bearer"))
            .components(new Components().addSecuritySchemes("Bearer",
                new SecurityScheme()
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")
                    .description("JWT généré par POST /api/v1/auth/login")));
    }
}
JEOF

cat > "$P/api/config/RateLimitConfig.java" << 'JEOF'
package com.mbem.mbemlevel.api.config;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
/**
 * Rate limiting Bucket4j par IP.
 * Limites configurées dans application.yaml (mbemnova.rate-limit.*).
 */
@Component
@RequiredArgsConstructor
public class RateLimitConfig {
    // Cache local des buckets par clé (IP+endpoint)
    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

    /** Retourne ou crée un bucket pour une clé donnée. */
    public Bucket resolveBucket(String key, int capacity, Duration refillDuration) {
        return buckets.computeIfAbsent(key, k ->
            Bucket.builder()
                .addLimit(Bandwidth.builder()
                    .capacity(capacity)
                    .refillGreedy(capacity, refillDuration)
                    .build())
                .build());
    }
}
JEOF

cat > "$P/api/config/ActuatorSecurityConfig.java" << 'JEOF'
package com.mbem.mbemlevel.api.config;
import org.springframework.boot.actuate.autoconfigure.security.servlet.EndpointRequest;
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
JEOF

ok "ApplicationConfig · JwtConfig · WebConfig · OpenApiConfig · RateLimitConfig · ActuatorSecurityConfig"

# =============================================================================
sec "2/5 SecurityConfig + Filtres"
# =============================================================================
mkdir -p "$P/api/filter"
mkdir -p "$P/api/security"

cat > "$P/api/config/SecurityConfig.java" << 'JEOF'
package com.mbem.mbemlevel.api.config;
import com.mbem.mbemlevel.api.filter.*;
import com.mbem.mbemlevel.api.security.*;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.*;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.*;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
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
                .requestMatchers("/api/v1/admin/**").hasAnyRole("ADMIN","SUPER_ADMIN")
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

    @Bean
    public AuthenticationProvider authProvider() {
        var p = new org.springframework.security.authentication.dao.DaoAuthenticationProvider();
        p.setUserDetailsService(userDetailsService);
        p.setPasswordEncoder(new ApplicationConfig().passwordEncoder());
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
            "http://localhost:3000","http://localhost:5173",
            "https://mbemnova.com","https://www.mbemnova.com","https://app.mbemnova.com"));
        cfg.setAllowedMethods(List.of("GET","POST","PUT","PATCH","DELETE","OPTIONS"));
        cfg.setAllowedHeaders(List.of("Authorization","Content-Type","Accept","X-Request-ID"));
        cfg.setAllowCredentials(true);
        cfg.setMaxAge(3600L);
        var src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/api/**", cfg);
        return src;
    }
}
JEOF
ok "SecurityConfig.java"

cat > "$P/api/filter/JwtAuthenticationFilter.java" << 'JEOF'
package com.mbem.mbemlevel.api.filter;
import com.mbem.mbemlevel.infrastructure.security.token.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.*;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.List;
/**
 * Filtre JWT — extrait, valide Bearer token, peuple SecurityContext.
 * Fail-secure : erreur = SecurityContext vidé, requête rejetée par Spring Security.
 */
@Component @RequiredArgsConstructor @Slf4j
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final JwtTokenProvider    jwtProvider;
    private final TokenBlacklistService blacklist;

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest req,
            @NonNull HttpServletResponse res, @NonNull FilterChain chain)
            throws ServletException, IOException {
        String token = extract(req);
        if (token != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            try {
                if (blacklist.estBlackliste(token)) { chain.doFilter(req, res); return; }
                var claims = jwtProvider.validerEtExtraireClaims(token);
                String userId = claims.getSubject();
                String role   = (String) claims.getClaim("role");
                String email  = (String) claims.getClaim("email");
                var auth = new UsernamePasswordAuthenticationToken(userId, null,
                    List.of(new SimpleGrantedAuthority("ROLE_" + role)));
                auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(req));
                SecurityContextHolder.getContext().setAuthentication(auth);
                MDC.put("userId", userId); MDC.put("userEmail", email);
            } catch (Exception e) {
                SecurityContextHolder.clearContext();
                log.debug("[JWT] Token invalide: {}", e.getMessage());
            }
        }
        chain.doFilter(req, res);
    }

    private String extract(HttpServletRequest req) {
        String h = req.getHeader("Authorization");
        return (h != null && h.startsWith("Bearer ")) ? h.substring(7) : null;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        String p = req.getRequestURI();
        return p.startsWith("/api/v1/auth/") || p.startsWith("/actuator/health")
            || p.startsWith("/swagger-ui") || p.startsWith("/v3/api-docs");
    }
}
JEOF

cat > "$P/api/filter/RateLimitFilter.java" << 'JEOF'
package com.mbem.mbemlevel.api.filter;
import com.mbem.mbemlevel.api.config.RateLimitConfig;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.time.Duration;
/** Rate limiting Bucket4j : 100 req/min API générale, limites spéciales sur /auth. */
@Component @RequiredArgsConstructor
public class RateLimitFilter extends OncePerRequestFilter {
    private final RateLimitConfig rateLimitConfig;

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest req,
            @NonNull HttpServletResponse res, @NonNull FilterChain chain)
            throws ServletException, IOException {
        String ip   = getClientIp(req);
        String path = req.getRequestURI();
        int cap; Duration dur;
        if (path.contains("/auth/login"))          { cap = 10; dur = Duration.ofMinutes(1); }
        else if (path.contains("/auth/register"))  { cap = 5;  dur = Duration.ofMinutes(1); }
        else if (path.contains("/reset-password")) { cap = 3;  dur = Duration.ofHours(1); }
        else                                       { cap = 100; dur = Duration.ofMinutes(1); }

        String key    = path.replaceAll("/[0-9a-f-]{36}", "/{id}") + ":" + ip;
        var    bucket = rateLimitConfig.resolveBucket(key, cap, dur);

        if (bucket.tryConsume(1)) {
            res.addHeader("X-Rate-Limit-Remaining",
                String.valueOf(bucket.getAvailableTokens()));
            chain.doFilter(req, res);
        } else {
            res.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            res.setContentType("application/json;charset=UTF-8");
            res.getWriter().write("{\"success\":false,\"message\":\"Trop de requêtes. Réessayez dans quelques instants.\",\"error\":{\"code\":\"RATE_LIMIT_EXCEEDED\"}}");
        }
    }

    private String getClientIp(HttpServletRequest req) {
        String fwd = req.getHeader("X-Forwarded-For");
        return (fwd != null && !fwd.isBlank()) ? fwd.split(",")[0].trim() : req.getRemoteAddr();
    }
}
JEOF

cat > "$P/api/filter/RequestLoggingFilter.java" << 'JEOF'
package com.mbem.mbemlevel.api.filter;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.UUID;
/** MDC : requestId, method, path, ip — injectés dans tous les logs de la requête. */
@Component @Slf4j
public class RequestLoggingFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest req,
            @NonNull HttpServletResponse res, @NonNull FilterChain chain)
            throws ServletException, IOException {
        String rid = UUID.randomUUID().toString().replace("-","").substring(0, 16);
        long   t0  = System.currentTimeMillis();
        try {
            MDC.put("requestId", rid);
            MDC.put("method", req.getMethod());
            MDC.put("path",   req.getRequestURI());
            MDC.put("ip",     getIp(req));
            res.setHeader("X-Request-ID", rid);
            chain.doFilter(req, res);
        } finally {
            long ms = System.currentTimeMillis() - t0;
            if (ms > 2000) log.warn("[PERF] Requête lente {}ms {} {}", ms, req.getMethod(), req.getRequestURI());
            else           log.debug("[REQ] {} {} → {} ({}ms)", req.getMethod(), req.getRequestURI(), res.getStatus(), ms);
            MDC.clear();
        }
    }
    private String getIp(HttpServletRequest r) {
        String h = r.getHeader("X-Forwarded-For");
        return (h != null && !h.isBlank()) ? h.split(",")[0].trim() : r.getRemoteAddr();
    }
}
JEOF

cat > "$P/api/filter/SecurityHeadersFilter.java" << 'JEOF'
package com.mbem.mbemlevel.api.filter;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
/** Headers sécurité HTTP supplémentaires : Permissions-Policy, Cache-Control API. */
@Component
public class SecurityHeadersFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest req,
            @NonNull HttpServletResponse res, @NonNull FilterChain chain)
            throws ServletException, IOException {
        res.setHeader("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
        if (req.getRequestURI().startsWith("/api/")) {
            res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
            res.setHeader("Pragma", "no-cache");
        }
        chain.doFilter(req, res);
    }
}
JEOF

cat > "$P/api/security/UserDetailsServiceImpl.java" << 'JEOF'
package com.mbem.mbemlevel.api.security;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;
import java.util.List;
@Service @RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {
    private final UtilisateurRepository repo;
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        var u = repo.findByEmail(email)
            .orElseThrow(() -> new UsernameNotFoundException("Utilisateur non trouvé: " + email));
        return User.builder()
            .username(u.getId().toString())
            .password(u.getMotDePasseHache())
            .authorities(List.of(new SimpleGrantedAuthority(u.getRole().toSpringRole())))
            .accountLocked(u.estBloque())
            .build();
    }
}
JEOF

cat > "$P/api/security/CustomAuthEntryPoint.java" << 'JEOF'
package com.mbem.mbemlevel.api.security;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.servlet.http.*;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;
import java.io.IOException;
import java.time.LocalDateTime;
/** 401 JSON — remplace la redirection HTML par défaut de Spring Security. */
@Component
public class CustomAuthEntryPoint implements AuthenticationEntryPoint {
    private static final ObjectMapper M = new ObjectMapper().registerModule(new JavaTimeModule());
    @Override
    public void commence(HttpServletRequest req, HttpServletResponse res,
            AuthenticationException ex) throws IOException {
        res.setStatus(401); res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        M.writeValue(res.getWriter(), java.util.Map.of(
            "success", false, "message", "Authentification requise.",
            "error", java.util.Map.of("code","UNAUTHORIZED"), "timestamp", LocalDateTime.now().toString()));
    }
}
JEOF

cat > "$P/api/security/CustomAccessDeniedHandler.java" << 'JEOF'
package com.mbem.mbemlevel.api.security;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.servlet.http.*;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;
import java.io.IOException;
import java.time.LocalDateTime;
/** 403 JSON — droits insuffisants. */
@Component
public class CustomAccessDeniedHandler implements AccessDeniedHandler {
    private static final ObjectMapper M = new ObjectMapper().registerModule(new JavaTimeModule());
    @Override
    public void handle(HttpServletRequest req, HttpServletResponse res,
            AccessDeniedException ex) throws IOException {
        res.setStatus(403); res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        M.writeValue(res.getWriter(), java.util.Map.of(
            "success", false, "message", "Accès refusé. Droits insuffisants.",
            "error", java.util.Map.of("code","ACCESS_DENIED"), "timestamp", LocalDateTime.now().toString()));
    }
}
JEOF
ok "SecurityConfig · 4 filtres · UserDetails · EntryPoint · AccessDenied"

# =============================================================================
sec "3/5 DTOs HTTP (réponses + requêtes)"
# =============================================================================
mkdir -p "$P/api/dto/response"
mkdir -p "$P/api/dto/request"

cat > "$P/api/dto/response/ApiResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import java.util.List;
/**
 * Wrapper universel pour toutes les réponses HTTP MbemNova.
 * success=true → data présente · success=false → error présente
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(
    boolean success, String message, T data, ErrorDetail error, LocalDateTime timestamp
) {
    public static <T> ApiResponse<T> ok(T data, String msg) {
        return new ApiResponse<>(true, msg, data, null, LocalDateTime.now()); }
    public static <T> ApiResponse<T> ok(T data) { return ok(data, "OK"); }
    public static <T> ApiResponse<T> ok(String msg) {
        return new ApiResponse<>(true, msg, null, null, LocalDateTime.now()); }
    public static <T> ApiResponse<T> err(String msg, String code) {
        return new ApiResponse<>(false, msg, null, new ErrorDetail(code, null), LocalDateTime.now()); }
    public static <T> ApiResponse<T> validation(String msg, List<String> details) {
        return new ApiResponse<>(false, msg, null, new ErrorDetail("VALIDATION_ERROR", details), LocalDateTime.now()); }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record ErrorDetail(String code, List<String> details) {}
}
JEOF

cat > "$P/api/dto/response/PageResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import org.springframework.data.domain.Page;
import java.util.List;
/** Wrapper pagination universel. */
public record PageResponse<T>(
    List<T> content, int page, int size,
    long totalElements, int totalPages, boolean last
) {
    public static <T> PageResponse<T> of(Page<T> page) {
        return new PageResponse<>(page.getContent(), page.getNumber(), page.getSize(),
            page.getTotalElements(), page.getTotalPages(), page.isLast());
    }
}
JEOF

cat > "$P/api/dto/response/AuthResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import java.util.UUID;
/** Réponse auth : JWT + refresh token + infos utilisateur. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record AuthResponse(
    UUID userId, String prenom, String email, String role,
    String accessToken, String refreshToken,
    LocalDateTime expiresAt, Boolean suspended
) {}
JEOF

cat > "$P/api/dto/response/ErrorResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import java.time.LocalDateTime;
import java.util.List;
/** Réponse d'erreur HTTP détaillée. */
public record ErrorResponse(
    int status, String code, String message,
    List<String> details, LocalDateTime timestamp
) {}
JEOF

# Request DTOs
cat > "$P/api/dto/request/InscriptionRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record InscriptionRequest(
    @NotBlank @Size(min=2,max=50)
    @Pattern(regexp="^[\\p{L}\\s'-]+$", message="Caractères invalides")
    String prenom,
    @NotBlank @Email @Size(max=255)
    String email,
    @NotBlank @Size(min=8,max=100,message="8 caractères minimum")
    String motDePasse
) {}
JEOF

cat > "$P/api/dto/request/ConnexionRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record ConnexionRequest(
    @NotBlank @Email String email,
    @NotBlank String motDePasse,
    boolean rememberMe
) {}
JEOF

cat > "$P/api/dto/request/RefreshTokenRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.NotBlank;
public record RefreshTokenRequest(@NotBlank String refreshToken) {}
JEOF

cat > "$P/api/dto/request/ResetPasswordRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record ResetPasswordRequest(@NotBlank @Email String email) {}
JEOF

cat > "$P/api/dto/request/NouveauMotDePasseRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record NouveauMotDePasseRequest(
    @NotBlank String token,
    @NotBlank @Size(min=8,max=100) String nouveauMotDePasse
) {}
JEOF

ok "ApiResponse · PageResponse · AuthResponse · 5 request DTOs"

# =============================================================================
sec "4/5 GlobalExceptionHandler + Exceptions"
# =============================================================================
mkdir -p "$P/api/exception"

cat > "$P/api/exception/MbemNovaException.java" << 'JEOF'
package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class MbemNovaException extends RuntimeException {
    private final HttpStatus status;
    private final String     code;
    public MbemNovaException(String msg, HttpStatus status, String code) {
        super(msg); this.status = status; this.code = code;
    }
    public HttpStatus getStatus() { return status; }
    public String     getCode()   { return code; }
}
JEOF

for entry in \
  "EmailDejaUtiliseException:409:CONFLICT:EMAIL_ALREADY_EXISTS:Cet email est déjà utilisé." \
  "TokenExpireException:401:UNAUTHORIZED:TOKEN_EXPIRED:Token expiré. Reconnectez-vous." \
  "CompteSuspenduException:403:FORBIDDEN:ACCOUNT_SUSPENDED:Compte suspendu. Contactez MbemNova." \
  "RessourceIntrouvableException:404:NOT_FOUND:RESOURCE_NOT_FOUND:Ressource introuvable." \
  "AccesInterditException:403:FORBIDDEN:ACCESS_DENIED:Accès refusé." \
  "SeuilPaiementException:402:PAYMENT_REQUIRED:PAYMENT_REQUIRED:Paiement requis pour continuer." \
  "RateLimitException:429:TOO_MANY_REQUESTS:RATE_LIMIT_EXCEEDED:Trop de requêtes." \
  "FichierInvalideException:400:BAD_REQUEST:INVALID_FILE:Fichier invalide."
do
  IFS=: read -r cname code hstatus ecode msg <<< "$entry"
  cat > "$P/api/exception/${cname}.java" << JEOF
package com.mbem.mbemlevel.api.exception;
import org.springframework.http.HttpStatus;
public class ${cname} extends MbemNovaException {
    public ${cname}() { super("${msg}", HttpStatus.${hstatus}, "${ecode}"); }
    public ${cname}(String detail) { super(detail, HttpStatus.${hstatus}, "${ecode}"); }
}
JEOF
done

cat > "$P/api/exception/GlobalExceptionHandler.java" << 'JEOF'
package com.mbem.mbemlevel.api.exception;
import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.context.request.WebRequest;
import java.util.List;
import java.util.stream.Collectors;
/**
 * Gestionnaire global d'exceptions — toutes les erreurs → JSON cohérent.
 * NE JAMAIS exposer les stack traces ou messages techniques en réponse.
 */
@RestControllerAdvice @Slf4j
public class GlobalExceptionHandler {

    /** Exceptions métier MbemNova — code HTTP et code machine précis. */
    @ExceptionHandler(MbemNovaException.class)
    public ResponseEntity<ApiResponse<Void>> handle(MbemNovaException e) {
        log.debug("[EX] {}: {}", e.getCode(), e.getMessage());
        return ResponseEntity.status(e.getStatus())
            .body(ApiResponse.err(e.getMessage(), e.getCode()));
    }

    /** Bean Validation (@Valid) — retourne la liste des champs invalides. */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handle(MethodArgumentNotValidException e) {
        List<String> details = e.getBindingResult().getFieldErrors().stream()
            .map(FieldError::getDefaultMessage).collect(Collectors.toList());
        return ResponseEntity.unprocessableEntity()
            .body(ApiResponse.validation("Données invalides.", details));
    }

    /** Tentative de connexion avec mauvais identifiants — message générique. */
    @ExceptionHandler(SecurityException.class)
    public ResponseEntity<ApiResponse<Void>> handle(SecurityException e) {
        String code = e.getMessage();
        return switch (code) {
            case "EMAIL_ALREADY_EXISTS"     -> ResponseEntity.status(409).body(ApiResponse.err("Email déjà utilisé.", code));
            case "ACCOUNT_TEMPORARILY_LOCKED" -> ResponseEntity.status(403).body(ApiResponse.err("Compte temporairement bloqué.", code));
            case "ACCOUNT_SUSPENDED"        -> ResponseEntity.status(403).body(ApiResponse.err("Compte suspendu.", code));
            case "INVALID_REFRESH_TOKEN"    -> ResponseEntity.status(401).body(ApiResponse.err("Token de rafraîchissement invalide.", code));
            case "INVALID_OR_EXPIRED_RESET_TOKEN" -> ResponseEntity.status(400).body(ApiResponse.err("Lien de réinitialisation invalide ou expiré.", code));
            default -> ResponseEntity.status(401).body(ApiResponse.err("Email ou mot de passe incorrect.", "INVALID_CREDENTIALS"));
        };
    }

    /** Spring Security 401 */
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiResponse<Void>> handle(AuthenticationException e) {
        return ResponseEntity.status(401).body(ApiResponse.err("Authentification requise.", "UNAUTHORIZED"));
    }

    /** Spring Security 403 */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handle(AccessDeniedException e) {
        return ResponseEntity.status(403).body(ApiResponse.err("Accès refusé.", "ACCESS_DENIED"));
    }

    /** IllegalStateException — souvent email déjà utilisé depuis le use case. */
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<ApiResponse<Void>> handle(IllegalStateException e) {
        if ("EMAIL_ALREADY_EXISTS".equals(e.getMessage())) {
            return ResponseEntity.status(409).body(ApiResponse.err("Email déjà utilisé.", "EMAIL_ALREADY_EXISTS"));
        }
        log.warn("[EX] IllegalState: {}", e.getMessage());
        return ResponseEntity.badRequest().body(ApiResponse.err("Opération impossible.", "BAD_REQUEST"));
    }

    /** Toute exception non gérée → 500 générique sans détail technique. */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handle(Exception e, WebRequest req) {
        log.error("[EX] Erreur interne: {} — {}", e.getClass().getSimpleName(), e.getMessage(), e);
        return ResponseEntity.internalServerError()
            .body(ApiResponse.err("Erreur interne. Réessayez ou contactez le support.", "INTERNAL_ERROR"));
    }
}
JEOF
ok "GlobalExceptionHandler + 8 exceptions métier"

# =============================================================================
sec "5/5 AuthController + AOP Aspects"
# =============================================================================
mkdir -p "$P/api/controller"
mkdir -p "$P/api/aspect"

cat > "$P/api/controller/AuthController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.dto.request.*;
import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.usecase.auth.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * Endpoints d'authentification MbemNova.
 * Scénarios couverts : 02 (inscription), 03 (connexion), 27 (reset MDP).
 */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentification", description = "Inscription, connexion, tokens, reset MDP")
@RequiredArgsConstructor
public class AuthController {

    private final InscrireApprenantUseCase       inscrireUC;
    private final ConnecterUtilisateurUseCase    connecterUC;
    private final RefreshTokenUseCase            refreshUC;
    private final DeconnecterUseCase             deconnecterUC;
    private final ReinitialiserMotDePasseUseCase resetMdpUC;
    private final ConfirmerEmailUseCase          confirmerEmailUC;

    /** POST /api/v1/auth/register — Scénario 02 */
    @PostMapping("/register")
    @Operation(summary = "Créer un compte apprenant")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody InscriptionRequest req, HttpServletRequest httpReq) {
        AuthResultDto result = inscrireUC.executer(
            new InscriptionCommand(req.prenom(), req.email(), req.motDePasse(),
                getIp(httpReq), httpReq.getHeader("User-Agent")));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(toAuthResponse(result), "Compte créé !"));
    }

    /** POST /api/v1/auth/login — Scénario 03 */
    @PostMapping("/login")
    @Operation(summary = "Se connecter")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody ConnexionRequest req, HttpServletRequest httpReq) {
        AuthResultDto result = connecterUC.executer(
            new ConnexionCommand(req.email(), req.motDePasse(), req.rememberMe(),
                getIp(httpReq), httpReq.getHeader("User-Agent")));
        return ResponseEntity.ok(ApiResponse.ok(toAuthResponse(result), "Connexion réussie."));
    }

    /** POST /api/v1/auth/refresh */
    @PostMapping("/refresh")
    @Operation(summary = "Rafraîchir le JWT")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(
            @Valid @RequestBody RefreshTokenRequest req, HttpServletRequest httpReq) {
        AuthResultDto result = refreshUC.executer(req.refreshToken(),
            getIp(httpReq), httpReq.getHeader("User-Agent"));
        return ResponseEntity.ok(ApiResponse.ok(toAuthResponse(result)));
    }

    /** POST /api/v1/auth/logout */
    @PostMapping("/logout")
    @Operation(summary = "Se déconnecter")
    public ResponseEntity<ApiResponse<Void>> logout(
            HttpServletRequest httpReq,
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody(required = false) RefreshTokenRequest body,
            @AuthenticationPrincipal String userId) {
        String accessToken  = authHeader != null && authHeader.startsWith("Bearer ")
            ? authHeader.substring(7) : null;
        String refreshToken = body != null ? body.refreshToken() : null;
        String email        = httpReq.getUserPrincipal() != null ? httpReq.getUserPrincipal().getName() : "";
        deconnecterUC.executer(
            userId != null ? UUID.fromString(userId) : null,
            email, accessToken, refreshToken);
        return ResponseEntity.ok(ApiResponse.ok("Déconnexion réussie."));
    }

    /** POST /api/v1/auth/reset-password — Étape 1 : demander le lien (Scénario 27) */
    @PostMapping("/reset-password")
    @Operation(summary = "Demander la réinitialisation du mot de passe")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest req, HttpServletRequest httpReq) {
        // Toujours retourner 200 même si l'email n'existe pas (anti-énumération)
        resetMdpUC.demanderReset(req.email(), getIp(httpReq));
        return ResponseEntity.ok(ApiResponse.ok(
            "Si cet email est enregistré, vous recevrez un lien sous 5 minutes."));
    }

    /** POST /api/v1/auth/new-password — Étape 2 : confirmer le nouveau MDP */
    @PostMapping("/new-password")
    @Operation(summary = "Définir le nouveau mot de passe")
    public ResponseEntity<ApiResponse<Void>> newPassword(
            @Valid @RequestBody NouveauMotDePasseRequest req) {
        resetMdpUC.confirmerReset(req.token(), req.nouveauMotDePasse());
        return ResponseEntity.ok(ApiResponse.ok("Mot de passe mis à jour. Reconnectez-vous."));
    }

    /** GET /api/v1/auth/confirm-email?token=xxx */
    @GetMapping("/confirm-email")
    @Operation(summary = "Vérifier l'adresse email")
    public ResponseEntity<ApiResponse<Void>> confirmEmail(@RequestParam String token) {
        confirmerEmailUC.executer(token);
        return ResponseEntity.ok(ApiResponse.ok("Email vérifié."));
    }

    /** GET /api/v1/auth/me — Profil utilisateur connecté */
    @GetMapping("/me")
    @Operation(summary = "Profil utilisateur connecté")
    public ResponseEntity<ApiResponse<String>> me(@AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(ApiResponse.ok(userId));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private AuthResponse toAuthResponse(AuthResultDto d) {
        return new AuthResponse(d.utilisateurId(), d.prenom(), d.email(), d.role(),
            d.accessToken(), d.refreshToken(), d.expiresAt(), d.estSuspendu());
    }

    private String getIp(HttpServletRequest r) {
        String h = r.getHeader("X-Forwarded-For");
        return (h != null && !h.isBlank()) ? h.split(",")[0].trim() : r.getRemoteAddr();
    }
}
JEOF

cat > "$P/api/controller/HealthController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import org.springframework.boot.info.BuildProperties;
import org.springframework.context.annotation.Import;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.Map;
@RestController
@RequestMapping("/api/v1")
public class HealthController {
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> health() {
        return ResponseEntity.ok(ApiResponse.ok(
            Map.of("status","UP","timestamp", LocalDateTime.now().toString())));
    }
}
JEOF

cat > "$P/api/aspect/AuditTrailAspect.java" << 'JEOF'
package com.mbem.mbemlevel.api.aspect;
import com.mbem.mbemlevel.infrastructure.audit.AuditLogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.*;
import org.springframework.stereotype.Component;
import java.util.Map;
/**
 * Aspect AOP — trace automatiquement les actions sensibles (paiement, rôle, suspension).
 * Utilisé en complément des appels manuels dans les use cases.
 */
@Aspect @Component @RequiredArgsConstructor @Slf4j
public class AuditTrailAspect {
    private final AuditLogService auditService;

    @Around("@annotation(com.mbem.mbemlevel.api.aspect.Auditable)")
    public Object audit(ProceedingJoinPoint pjp) throws Throwable {
        String action = pjp.getSignature().getName().toUpperCase();
        try {
            Object result = pjp.proceed();
            log.debug("[AUDIT] {} OK", action);
            return result;
        } catch (Exception e) {
            auditService.echec(null, null, action + "_FAILURE", null, null,
                Map.of("error", e.getMessage()));
            throw e;
        }
    }
}
JEOF

cat > "$P/api/aspect/Auditable.java" << 'JEOF'
package com.mbem.mbemlevel.api.aspect;
import java.lang.annotation.*;
/** Marque une méthode à tracer automatiquement dans l'audit log. */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Auditable {}
JEOF

cat > "$P/api/aspect/PerformanceAspect.java" << 'JEOF'
package com.mbem.mbemlevel.api.aspect;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.*;
import org.springframework.stereotype.Component;
/** Alerte si un use case dépasse 500ms (détecte les requêtes N+1, locks BDD). */
@Aspect @Component @Slf4j
public class PerformanceAspect {
    @Around("execution(* com.mbem.mbemlevel.application.usecase.*.*(..))")
    public Object measure(ProceedingJoinPoint pjp) throws Throwable {
        long t0 = System.currentTimeMillis();
        Object r = pjp.proceed();
        long ms = System.currentTimeMillis() - t0;
        if (ms > 500) log.warn("[PERF] {} — {}ms (seuil 500ms dépassé)", pjp.getSignature().toShortString(), ms);
        return r;
    }
}
JEOF

ok "AuthController · HealthController · AuditTrailAspect · PerformanceAspect"

# Résumé
echo -e "\n${C_B}${C_G}  Script 08 terminé${NC}"
echo -e "  ${C_G}✓${NC} SecurityConfig + 4 filtres + UserDetails + EntryPoints"
echo -e "  ${C_G}✓${NC} GlobalExceptionHandler + 8 exceptions"
echo -e "  ${C_G}✓${NC} ApiResponse, PageResponse, AuthResponse + 5 request DTOs"
echo -e "  ${C_G}✓${NC} AuthController (7 endpoints · scénarios 02,03,27)"
echo -e "  ${C_G}✓${NC} AuditTrailAspect + PerformanceAspect\n"
echo -e "  \033[1;33m→ ./s09_cours_progression.sh\033[0m\n"
