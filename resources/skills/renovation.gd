class_name Renovation extends Skill

@export var heal_amount: int = 30
@export var duration: float = 5.0
@export var tick_interval: float = 1.0


func _init() -> void:
    is_hot_or_dot = true


func execute(player: Player, _target_position: Vector2) -> void:
    print("Renovation.gd - execute()")
    if is_on_cooldown():
        return
    var target: Node3D = player.selected_entity
    if target == null:
        return
    if not target.has_method("heal"):
        return
    last_used_time = Time.get_unix_time_from_system()
    _heal_over_time(player, target)


func _heal_over_time(player: Player, target: Node3D) -> void:
    if tick_interval <= 0.0 or duration <= 0.0:
        return

    var tick_count := int(floor(duration / tick_interval))
    for _tick in range(tick_count):
        await player.get_tree().create_timer(tick_interval).timeout
        if not is_instance_valid(target) or not target.has_method("heal"):
            return
        target.heal(heal_amount)
