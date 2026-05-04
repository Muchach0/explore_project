class_name HealSkill extends Skill

@export var heal_amount: int = 10

func _init() -> void:
    skill_name = "Heal"
    cooldown = 1.0

func execute(player: Player, target_position: Vector2) -> void:
    print("HealSkill.gd - execute()")
    if is_on_cooldown():
        return
    var target: Node3D = player.selected_entity
    if target == null:
        return
    if not target.has_method("heal"):
        return
    last_used_time = Time.get_unix_time_from_system()
    target.heal(heal_amount)
