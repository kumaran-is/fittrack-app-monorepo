package com.fitness.api.session;

import com.fitness.api.auth.dto.RegisterRequest;
import com.fitness.api.auth.dto.TokenResponse;
import com.fitness.api.exercise.dto.ExerciseResponse;
import com.fitness.api.session.dto.SessionRequest;
import com.fitness.api.session.dto.SessionResponse;
import com.fitness.api.session.dto.SetRequest;
import com.fitness.api.session.dto.SetResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.reactive.AutoConfigureWebTestClient;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.reactive.server.WebTestClient;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWebTestClient
class WorkoutSessionControllerTest {

    @Autowired
    private WebTestClient webTestClient;

    private String authToken;
    private UUID anyExerciseId;

    @BeforeEach
    void setUp() {
        RegisterRequest registerRequest = new RegisterRequest(
                "session-test-" + UUID.randomUUID() + "@example.com",
                "password123",
                "Session Tester"
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

        // Grab a seeded exercise for logging sets
        List<ExerciseResponse> exercises = webTestClient.get().uri("/api/v1/exercises")
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isOk()
                .expectBodyList(ExerciseResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(exercises).isNotNull().isNotEmpty();
        anyExerciseId = exercises.get(0).id();
    }

    @Test
    void startSession_shouldReturn201WithSessionId() {
        SessionRequest request = new SessionRequest("Morning Push", null);

        SessionResponse response = webTestClient.post().uri("/api/v1/sessions")
                .header("Authorization", authToken)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(SessionResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(response).isNotNull();
        assertThat(response.id()).isNotNull();
        assertThat(response.name()).isEqualTo("Morning Push");
        assertThat(response.completed()).isFalse();
        assertThat(response.sets()).isEmpty();
    }

    @Test
    void logSet_shouldReturn201WithSetDetails() {
        SessionResponse session = startSession("Push Day");

        SetRequest setRequest = new SetRequest(anyExerciseId, 1, 10, BigDecimal.valueOf(100), "Felt good");

        SetResponse setResponse = webTestClient.post()
                .uri("/api/v1/sessions/" + session.id() + "/sets")
                .header("Authorization", authToken)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(setRequest)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(SetResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(setResponse).isNotNull();
        assertThat(setResponse.id()).isNotNull();
        assertThat(setResponse.setNumber()).isEqualTo(1);
        assertThat(setResponse.reps()).isEqualTo(10);
        assertThat(setResponse.weightKg()).isEqualByComparingTo(BigDecimal.valueOf(100));
    }

    @Test
    void completeSession_shouldMarkSessionCompleted() {
        SessionResponse session = startSession("Pull Day");

        SessionResponse completed = webTestClient.patch()
                .uri("/api/v1/sessions/" + session.id() + "/complete")
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isOk()
                .expectBody(SessionResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(completed).isNotNull();
        assertThat(completed.completed()).isTrue();
        assertThat(completed.completedAt()).isNotNull();
    }

    @Test
    void getSession_withSets_shouldReturnFullDetails() {
        SessionResponse session = startSession("Leg Day");

        webTestClient.post()
                .uri("/api/v1/sessions/" + session.id() + "/sets")
                .header("Authorization", authToken)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(new SetRequest(anyExerciseId, 1, 5, BigDecimal.valueOf(140), null))
                .exchange()
                .expectStatus().isCreated();

        webTestClient.post()
                .uri("/api/v1/sessions/" + session.id() + "/sets")
                .header("Authorization", authToken)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(new SetRequest(anyExerciseId, 2, 5, BigDecimal.valueOf(145), null))
                .exchange()
                .expectStatus().isCreated();

        SessionResponse fetched = webTestClient.get()
                .uri("/api/v1/sessions/" + session.id())
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isOk()
                .expectBody(SessionResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(fetched).isNotNull();
        assertThat(fetched.sets()).hasSize(2);
    }

    @Test
    void getSessions_paginatedHistory_shouldReturnResults() {
        startSession("History Session 1");
        startSession("History Session 2");

        List<SessionResponse> sessions = webTestClient.get()
                .uri("/api/v1/sessions?page=0&size=20")
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isOk()
                .expectBodyList(SessionResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(sessions).isNotNull();
        assertThat(sessions.size()).isGreaterThanOrEqualTo(2);
    }

    @Test
    void deleteSet_shouldReturn204() {
        SessionResponse session = startSession("Delete Set Test");
        SetRequest setRequest = new SetRequest(anyExerciseId, 1, 8, BigDecimal.valueOf(60), null);

        SetResponse set = webTestClient.post()
                .uri("/api/v1/sessions/" + session.id() + "/sets")
                .header("Authorization", authToken)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(setRequest)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(SetResponse.class)
                .returnResult()
                .getResponseBody();

        assertThat(set).isNotNull();

        webTestClient.delete()
                .uri("/api/v1/sessions/" + session.id() + "/sets/" + set.id())
                .header("Authorization", authToken)
                .exchange()
                .expectStatus().isNoContent();
    }

    private SessionResponse startSession(String name) {
        SessionRequest request = new SessionRequest(name, null);
        SessionResponse response = webTestClient.post().uri("/api/v1/sessions")
                .header("Authorization", authToken)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(SessionResponse.class)
                .returnResult()
                .getResponseBody();
        assertThat(response).isNotNull();
        return response;
    }
}
