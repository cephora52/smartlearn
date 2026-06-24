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
