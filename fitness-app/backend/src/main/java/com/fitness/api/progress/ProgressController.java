package com.fitness.api.progress;

import com.fitness.api.progress.dto.WeeklyStrengthPoint;
import com.fitness.api.progress.dto.WeeklyVolumePoint;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/progress")
public class ProgressController {

    private final ProgressService progressService;

    public ProgressController(ProgressService progressService) {
        this.progressService = progressService;
    }

    @GetMapping("/exercises/{exerciseId}")
    public Flux<WeeklyStrengthPoint> getStrengthProgress(@PathVariable UUID exerciseId) {
        return currentUserId()
                .flatMapMany(userId -> progressService.getStrengthProgress(exerciseId, userId));
    }

    @GetMapping("/volume")
    public Flux<WeeklyVolumePoint> getVolumeProgress() {
        return currentUserId()
                .flatMapMany(progressService::getVolumeProgress);
    }

    private Mono<UUID> currentUserId() {
        return ReactiveSecurityContextHolder.getContext()
                .map(ctx -> UUID.fromString(ctx.getAuthentication().getName()));
    }
}
