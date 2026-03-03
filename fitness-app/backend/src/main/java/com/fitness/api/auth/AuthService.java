package com.fitness.api.auth;

import com.fitness.api.auth.dto.LoginRequest;
import com.fitness.api.auth.dto.RegisterRequest;
import com.fitness.api.auth.dto.TokenResponse;
import com.fitness.api.config.JwtService;
import com.fitness.api.exception.UnauthorizedException;
import com.fitness.api.exception.ValidationException;
import com.fitness.api.user.User;
import com.fitness.api.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public Mono<TokenResponse> register(RegisterRequest request) {
        return userRepository.existsByEmail(request.email())
                .flatMap(exists -> {
                    if (exists) {
                        return Mono.error(new ValidationException("Email already registered: " + request.email()));
                    }
                    return Mono.fromCallable(() -> passwordEncoder.encode(request.password()))
                            .subscribeOn(Schedulers.boundedElastic())
                            .flatMap(hash -> {
                                User user = new User();
                                user.setEmail(request.email());
                                user.setPasswordHash(hash);
                                user.setDisplayName(request.displayName());
                                return userRepository.save(user);
                            });
                })
                .map(saved -> {
                    String token = jwtService.generateToken(saved.getId(), saved.getEmail());
                    log.info("User registered: userId={}", saved.getId());
                    return new TokenResponse(token, saved.getId(), saved.getDisplayName());
                });
    }

    public Mono<TokenResponse> login(LoginRequest request) {
        return userRepository.findByEmail(request.email())
                .switchIfEmpty(Mono.error(new UnauthorizedException("Invalid email or password")))
                .flatMap(user -> Mono.fromCallable(
                        () -> passwordEncoder.matches(request.password(), user.getPasswordHash()))
                        .subscribeOn(Schedulers.boundedElastic())
                        .flatMap(matches -> {
                            if (!matches) {
                                return Mono.error(new UnauthorizedException("Invalid email or password"));
                            }
                            String token = jwtService.generateToken(user.getId(), user.getEmail());
                            log.info("User logged in: userId={}", user.getId());
                            return Mono.just(new TokenResponse(token, user.getId(), user.getDisplayName()));
                        }));
    }
}
