package com.fitness.api.exercise;

import com.fitness.api.auth.dto.RegisterRequest;
import com.fitness.api.auth.dto.TokenResponse;
import com.fitness.api.exercise.dto.ExerciseRequest;
import com.fitness.api.exercise.dto.ExerciseResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.reactive.AutoConfigureWebTestClient;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.reactive.server.WebTestClient;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWebTestClient
class ExerciseControllerTest {

    @Autowired
    private WebTestClient webTestClient;

    private String authToken;

    @BeforeEach
    void setUp() {
        RegisterRequest registerRequest = new RegisterRequest(
                "exercise-test-" + UUID.randomUUID() + "@example.com",
                "password123",
                "Exercise Tester"
        );

        TokenResponse tokenResponse = webTestClient.post().uri("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(registerRequest)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(TokenResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(tokenResponse).isNotNull();
        authToken = "Bearer " + tokenResponse.token();
    }

    @Test
    void getAll_withValidToken_shouldReturnSeededExercises() {
        List<ExerciseResponse> exercises = webTestClient.get().uri("/api/v1/exercises")
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isOk()
                .expectBodyList(ExerciseResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(exercises).isNotNull();
        assertThat(exercises).hasSizeGreaterThanOrEqualTo(30);
    }

    @Test
    void getAll_filterByCategory_shouldReturnOnlyMatchingExercises() {
        List<ExerciseResponse> exercises = webTestClient.get()
                .uri("/api/v1/exercises?category=CHEST")
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isOk()
                .expectBodyList(ExerciseResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(exercises).isNotNull();
        assertThat(exercises).isNotEmpty();
        assertThat(exercises).allMatch(e -> e.category().equals("CHEST"));
    }

    @Test
    void getAll_textSearch_shouldReturnMatchingExercises() {
        List<ExerciseResponse> exercises = webTestClient.get()
                .uri("/api/v1/exercises?q=squat")
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isOk()
                .expectBodyList(ExerciseResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(exercises).isNotNull();
        assertThat(exercises).isNotEmpty();
        assertThat(exercises).anyMatch(e -> e.name().toLowerCase().contains("squat"));
    }

    @Test
    void create_withValidRequest_shouldReturn201() {
        ExerciseRequest request = new ExerciseRequest(
                "Custom Cable Row", "BACK", "Rhomboids", "Custom variation"
        );

        ExerciseResponse response = webTestClient.post().uri("/api/v1/exercises")
                .header("Authorization", authToken)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(ExerciseResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(response).isNotNull();
        assertThat(response.id()).isNotNull();
        assertThat(response.name()).isEqualTo("Custom Cable Row");
        assertThat(response.isCustom()).isTrue();
    }

    @Test
    void delete_ownExercise_shouldReturn204() {
        ExerciseRequest request = new ExerciseRequest("My Exercise", "ARMS", "Biceps", "Custom");

        ExerciseResponse created = webTestClient.post().uri("/api/v1/exercises")
                .header("Authorization", authToken)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(ExerciseResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(created).isNotNull();

        webTestClient.delete().uri("/api/v1/exercises/" + created.id())
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isNoContent();
    }

    @Test
    void delete_systemExercise_shouldReturn403() {
        // Get a system exercise (one with isCustom=false)
        List<ExerciseResponse> exercises = webTestClient.get().uri("/api/v1/exercises")
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isOk()
                .expectBodyList(ExerciseResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(exercises).isNotNull();
        ExerciseResponse systemExercise = exercises.stream()
                .filter(e -> !e.isCustom())
                .findFirst()
                .orElseThrow();

        webTestClient.delete().uri("/api/v1/exercises/" + systemExercise.id())
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isForbidden();
    }

    @Test
    void delete_withoutToken_shouldReturn401() {
        webTestClient.delete().uri("/api/v1/exercises/" + UUID.randomUUID())
                .exchange()
                .expectStatus().isUnauthorized();
    }
}
