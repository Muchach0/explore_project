class_name WanderingState
extends State

var _direction: Vector3 = Vector3.ZERO
var _timer: float = 0.0
var _duration: float = 0.0

func enter() -> void:
	var angle := randf_range(0.0, TAU)
	_direction = Vector3(cos(angle), 0.0, sin(angle)).normalized()
	_duration = randf_range(actor.wander_duration_min, actor.wander_duration_max)
	_timer = 0.0
	actor.play_animation("walk", true)

func exit() -> void:
	actor.velocity = Vector3.ZERO
	actor.play_animation("walk", false)

func update(delta: float) -> void:
	_timer += delta
	if actor.find_closest_short_term_target():
		transitioned.emit(self, "CombatState")
		return
	if _timer >= _duration:
		transitioned.emit(self, "IdleState")

func physics_update(_delta: float) -> void:
	actor.velocity = _direction * actor.wander_speed
	actor.move_and_slide()
