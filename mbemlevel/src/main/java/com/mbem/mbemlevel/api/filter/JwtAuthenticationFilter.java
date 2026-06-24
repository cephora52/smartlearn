package com.mbem.mbemlevel.api.filter;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
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
    private final UtilisateurRepository utilisateurRepository;

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
                boolean emailVerifie = utilisateurRepository.findById(java.util.UUID.fromString(userId))
                    .map(com.mbem.mbemlevel.domain.user.Utilisateur::isEmailVerifie)
                    .orElse(false);
                if (!emailVerifie) {
                    SecurityContextHolder.clearContext();
                    chain.doFilter(req, res);
                    return;
                }
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
