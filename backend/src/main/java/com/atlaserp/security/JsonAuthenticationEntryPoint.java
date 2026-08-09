package com.atlaserp.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.Instant;

@Component
public class JsonAuthenticationEntryPoint implements AuthenticationEntryPoint {

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                          AuthenticationException authException) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        String json = """
                {"error":{"code":"NO_AUTENTICADO","message":"Se requiere autenticacion para acceder a este recurso","status":401,"timestamp":"%s","path":"%s"}}
                """.formatted(Instant.now(), request.getRequestURI().replace("\"", "\\\""));
        response.getWriter().write(json);
    }
}
