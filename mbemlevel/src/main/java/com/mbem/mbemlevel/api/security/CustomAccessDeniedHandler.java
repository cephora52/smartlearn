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
