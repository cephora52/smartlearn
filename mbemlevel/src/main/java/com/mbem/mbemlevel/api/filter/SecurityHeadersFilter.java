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
