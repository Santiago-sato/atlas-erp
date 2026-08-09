package com.atlaserp.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.Instant;

@Component
public class JsonAccessDeniedHandler implements AccessDeniedHandler {

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response,
                        AccessDeniedException accessDeniedException) throws IOException {
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("application/json");
        String json = """
                {"error":{"code":"ACCESO_DENEGADO","message":"No tenes permiso para realizar esta accion","status":403,"timestamp":"%s","path":"%s"}}
                """.formatted(Instant.now(), request.getRequestURI().replace("\"", "\\\""));
        response.getWriter().write(json);
    }
}
