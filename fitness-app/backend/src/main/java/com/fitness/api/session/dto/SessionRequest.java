package com.fitness.api.session.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record SessionRequest(
        @NotBlank String name,
        UUID planId
) {}
