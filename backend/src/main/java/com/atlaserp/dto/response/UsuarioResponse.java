package com.atlaserp.dto.response;

public record UsuarioResponse(
        Long id,
        String username,
        String email,
        String nombre,
        String apellido,
        String rol
) {
}
