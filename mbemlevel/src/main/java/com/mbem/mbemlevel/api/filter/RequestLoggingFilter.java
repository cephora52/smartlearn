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
