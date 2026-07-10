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
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) {
            chain.doFilter(req, res);
            return;
        }
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
