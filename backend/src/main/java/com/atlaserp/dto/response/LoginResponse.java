package com.atlaserp.dto.response;

public record LoginResponse(
        String accessToken,
        String tokenType,
        long expiresIn,
        UsuarioResponse user
) {
}
