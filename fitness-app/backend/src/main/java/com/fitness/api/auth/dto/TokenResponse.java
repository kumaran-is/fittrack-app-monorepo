package com.fitness.api.auth.dto;

import java.util.UUID;

public record TokenResponse(
        String token,
        UUID userId,
        String displayName
) {}
