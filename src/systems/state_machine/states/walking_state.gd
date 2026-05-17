class_name WalkingState
extends State

## NPC companion follow behavior.
## The entity walks toward actor.long_term_target and returns to Idle
## once within stop_distance, or if no target is found.

func enter() -> void:
    print("walking_state.gd() - transitioning to WalkiingState")
    if actor.long_term_target == null:
        actor.long_term_target = _find_closest_player()
    actor.play_animation("walk", true)

func exit() -> void:
    actor.velocity = Vector3.ZERO
    actor.play_animation("walk", false)

func update(_delta: float) -> void:
    if actor.find_closest_short_term_target():
        transitioned.emit(self, "CombatState")
        return
    if not is_instance_valid(actor.long_term_target):
        actor.long_term_target = null
        transitioned.emit(self, "IdleState")
        return
    var dist := actor.global_position.distance_to(actor.long_term_target.global_position)
    # if dist <= actor.stop_distance or dist > actor.give_up_range:
    if dist <= actor.stop_distance:
        transitioned.emit(self, "IdleState")

func physics_update(_delta: float) -> void:
    if not is_instance_valid(actor.long_term_target):
        actor.velocity = Vector3.ZERO
        return
    var dir := (actor.long_term_target.global_position - actor.global_position) * Vector3(1, 0, 1)
    actor.velocity = dir.normalized() * actor.walk_speed
    actor.move_and_slide()
