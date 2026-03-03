package com.fitness.api.auth;

import com.fitness.api.auth.dto.LoginRequest;
import com.fitness.api.auth.dto.RegisterRequest;
import com.fitness.api.auth.dto.TokenResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.reactive.AutoConfigureWebTestClient;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.reactive.server.WebTestClient;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWebTestClient
class AuthControllerTest {

    @Autowired
    private WebTestClient webTestClient;

    @Test
    void register_shouldReturn201WithToken() {
        RegisterRequest request = new RegisterRequest(
                "test-register-" + UUID.randomUUID() + "@example.com",
                "password123",
                "Test User"
        );

        webTestClient.post().uri("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(TokenResponse.class)
                .value(response -> {
                    assertThat(response.token()).isNotBlank();
                    assertThat(response.userId()).isNotNull();
                    assertThat(response.displayName()).isEqualTo("Test User");
                });
    }

    @Test
    void register_withDuplicateEmail_shouldReturn400() {
        String email = "duplicate-" + UUID.randomUUID() + "@example.com";
        RegisterRequest request = new RegisterRequest(email, "password123", "User One");

        webTestClient.post().uri("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated();

        webTestClient.post().uri("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isBadRequest();
    }

    @Test
    void register_withInvalidEmail_shouldReturn400() {
        RegisterRequest request = new RegisterRequest("not-an-email", "password123", "User");

        webTestClient.post().uri("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isBadRequest();
    }

    @Test
    void login_withValidCredentials_shouldReturnToken() {
        String email = "login-test-" + UUID.randomUUID() + "@example.com";
        RegisterRequest registerRequest = new RegisterRequest(email, "mypassword", "Login User");

        webTestClient.post().uri("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(registerRequest)
                .exchange()
                .expectStatus().isCreated();

        LoginRequest loginRequest = new LoginRequest(email, "mypassword");

        webTestClient.post().uri("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(loginRequest)
                .exchange()
                .expectStatus().isOk()
                .expectBody(TokenResponse.class)
                .value(response -> {
                    assertThat(response.token()).isNotBlank();
                    assertThat(response.userId()).isNotNull();
                });
    }

    @Test
    void login_withWrongPassword_shouldReturn403() {
        String email = "login-fail-" + UUID.randomUUID() + "@example.com";
        RegisterRequest registerRequest = new RegisterRequest(email, "correctpass", "Fail User");

        webTestClient.post().uri("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(registerRequest)
                .exchange()
                .expectStatus().isCreated();

        LoginRequest loginRequest = new LoginRequest(email, "wrongpass");

        webTestClient.post().uri("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(loginRequest)
                .exchange()
                .expectStatus().isForbidden();
    }

    @Test
    void exercises_withoutToken_shouldReturn401() {
        webTestClient.get().uri("/api/v1/exercises")
                .exchange()
                .expectStatus().isUnauthorized();
    }
}
