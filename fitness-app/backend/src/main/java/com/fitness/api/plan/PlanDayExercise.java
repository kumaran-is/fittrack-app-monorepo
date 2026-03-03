package com.fitness.api.plan;

import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.util.UUID;

@Table("plan_day_exercises")
public class PlanDayExercise {

    @Id
    private UUID id;

    @Column("day_id")
    private UUID dayId;

    @Column("exercise_id")
    private UUID exerciseId;

    private int sets;

    private int reps;

    @Column("rest_seconds")
    private int restSeconds;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getDayId() { return dayId; }
    public void setDayId(UUID dayId) { this.dayId = dayId; }

    public UUID getExerciseId() { return exerciseId; }
    public void setExerciseId(UUID exerciseId) { this.exerciseId = exerciseId; }

    public int getSets() { return sets; }
    public void setSets(int sets) { this.sets = sets; }

    public int getReps() { return reps; }
    public void setReps(int reps) { this.reps = reps; }

    public int getRestSeconds() { return restSeconds; }
    public void setRestSeconds(int restSeconds) { this.restSeconds = restSeconds; }
}
