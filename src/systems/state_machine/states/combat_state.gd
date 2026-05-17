class_name CombatState
extends State

var _target: Node3D = null
var _cooldown_timer: float = 0.0
var _can_attack: bool = true
var _attack_connected: bool = false

func enter() -> void:
	_target = actor.find_closest_short_term_target()
	_cooldown_timer = 0.0
	_can_attack = true
	_connect_attack_landed_signal()
	actor.set_hurtbox_active(true)
	actor.play_animation("walk", true)

func exit() -> void:
	_disconnect_attack_landed_signal()
	actor.set_hurtbox_active(false)
	actor.velocity = Vector3.ZERO
	actor.play_animation("walk", false)

func update(delta: float) -> void:
	if not _can_attack:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_can_attack = true
			actor.set_hurtbox_active(true)

	_target = actor.find_closest_short_term_target()
	if _target == null:
		if is_instance_valid(actor.long_term_target):
			transitioned.emit(self, "WalkingState")
		else:
			transitioned.emit(self, "IdleState")
		return

func physics_update(_delta: float) -> void:
	if _target == null or not _can_attack:
		actor.velocity = Vector3.ZERO
	else:
		var dir := (_target.global_position - actor.global_position) * Vector3(1, 0, 1)
		actor.velocity = dir.normalized() * actor.aggro_speed
	actor.move_and_slide()


func _connect_attack_landed_signal() -> void:
	if _attack_connected or not is_instance_valid(actor.hurtbox):
		return
	actor.hurtbox.attack_landed_signal.connect(_on_attack_landed)
	_attack_connected = true


func _disconnect_attack_landed_signal() -> void:
	if not _attack_connected or not is_instance_valid(actor.hurtbox):
		_attack_connected = false
		return
	actor.hurtbox.attack_landed_signal.disconnect(_on_attack_landed)
	_attack_connected = false


func _on_attack_landed() -> void:
	if not _can_attack:
		return
	_perform_attack()


func _perform_attack() -> void:
	_can_attack = false
	_cooldown_timer = actor.attack_cooldown
	actor.set_hurtbox_active(false)
	actor.attack()
