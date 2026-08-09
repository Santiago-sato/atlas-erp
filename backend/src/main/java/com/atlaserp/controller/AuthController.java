package com.atlaserp.controller;

import com.atlaserp.dto.request.LoginRequest;
import com.atlaserp.dto.response.ApiResponse;
import com.atlaserp.dto.response.LoginResponse;
import com.atlaserp.dto.response.UsuarioResponse;
import com.atlaserp.entity.Usuario;
import com.atlaserp.repository.UsuarioRepository;
import com.atlaserp.security.JwtService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UsuarioRepository usuarioRepository;
    private final JwtService jwtService;

    public AuthController(
            AuthenticationManager authenticationManager,
            UsuarioRepository usuarioRepository,
            JwtService jwtService) {
        this.authenticationManager = authenticationManager;
        this.usuarioRepository = usuarioRepository;
        this.jwtService = jwtService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.username(), request.password())
        );

        Usuario usuario = usuarioRepository.findByUsernameWithRolAndPermisos(request.username())
                .orElseThrow(() -> new IllegalStateException("Usuario autenticado pero no encontrado"));

        String token = jwtService.generateToken(usuario);

        UsuarioResponse usuarioResponse = new UsuarioResponse(
                usuario.getId(),
                usuario.getUsername(),
                usuario.getEmail(),
                usuario.getNombre(),
                usuario.getApellido(),
                usuario.getRol().getNombre()
        );

        LoginResponse loginResponse = new LoginResponse(
                token,
                "Bearer",
                jwtService.getExpirationMs() / 1000,
                usuarioResponse
        );

        return ResponseEntity.ok(ApiResponse.of(loginResponse));
    }
}
