package com.atlaserp.dto.response;

import java.time.Instant;
import java.util.List;

public record ErrorResponse(ErrorDetail error) {

    public record ErrorDetail(
            String code,
            String message,
            int status,
            Instant timestamp,
            String path,
            List<FieldError> fields
    ) {
    }

    public record FieldError(String field, String message) {
    }

    public static ErrorResponse of(String code, String message, int status, String path) {
        return new ErrorResponse(new ErrorDetail(code, message, status, Instant.now(), path, null));
    }

    public static ErrorResponse withFields(String code, String message, int status, String path, List<FieldError> fields) {
        return new ErrorResponse(new ErrorDetail(code, message, status, Instant.now(), path, fields));
    }
}
