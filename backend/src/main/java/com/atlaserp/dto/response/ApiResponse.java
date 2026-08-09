package com.atlaserp.dto.response;

import java.time.Instant;

public record ApiResponse<T>(T data, Meta meta) {

    public record Meta(Instant timestamp) {
    }

    public static <T> ApiResponse<T> of(T data) {
        return new ApiResponse<>(data, new Meta(Instant.now()));
    }
}
