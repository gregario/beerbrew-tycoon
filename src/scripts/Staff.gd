class_name Staff
extends Resource

## Staff resource — represents a brewery staff member.

@export var staff_id: String = ""
@export var staff_name: String = ""
@export var creativity: int = 50
@export var precision: int = 50
@export var experience_points: int = 0
@export var level: int = 1
@export var salary_per_turn: int = 60
@export var assigned_phase: String = ""
@export var specialization: String = "none"
@export var is_training: bool = false
@export var training_turns_remaining: int = 0
