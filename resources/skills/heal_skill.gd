class_name HealSkill extends Skill

@export var min_heal_amount: int = 15
@export var max_heal_amount: int = 25

func execute(player: Player, _target_position: Vector2) -> void:
    print("HealSkill.gd - execute()")
    if is_on_cooldown():
        return
    var target: Node3D = player.selected_entity
    if target == null:
        return
    if not target.has_method("heal"):
        return
    last_used_time = Time.get_unix_time_from_system()
    target.heal(randi_range(min_heal_amount, max_heal_amount))
