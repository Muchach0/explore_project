class_name IdleState
extends State

var _timer: float = 0.0
var _idle_duration: float = 0.0

func enter() -> void:
    actor.velocity = Vector3.ZERO
    _idle_duration = randf_range(actor.idle_duration_min, actor.idle_duration_max)
    _timer = 0.0

func update(delta: float) -> void:
    _timer += delta
    if actor.find_closest_short_term_target():
        transitioned.emit(self, "CombatState")
        return
    # follow_range: companion allies walk toward the nearest player without aggroing.
    if actor.follow_range > 0.0:
        var player := _find_closest_player()
        if player != null:
            var dist := actor.global_position.distance_to(player.global_position)
            if dist <= actor.follow_range and dist > actor.stop_distance:
                actor.long_term_target = player
                transitioned.emit(self, "WalkingState")
                return
    if _timer >= _idle_duration:
        if not actor.long_term_target:
            transitioned.emit(self, "WanderingState")
        else:
            transitioned.emit(self, "WalkingState")
