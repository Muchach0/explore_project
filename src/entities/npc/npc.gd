extends CharacterBody3D

const DAMAGE_LABEL_SCENE: PackedScene = preload("res://src/systems/health_and_damage_labels/DamageLabel.tscn")

@export var max_health: int = 100
var current_health: int

@onready var health_component: HealthComponent = $SubViewport/Npc2dModel/HealthComponent


func _ready() -> void:
    current_health = max_health
    health_component.init_life_bar(max_health)


func heal(amount: int) -> void:
    var actual_heal := mini(amount, max_health - current_health)
    if actual_heal <= 0:
        return
    current_health += actual_heal
    health_component.update_life_bar(current_health)
    _spawn_damage_label(amount)


func take_damage(amount: int) -> void:
    var actual_damage := mini(amount, current_health)
    if actual_damage <= 0:
        return
    current_health -= actual_damage
    health_component.update_life_bar(current_health)
    _spawn_damage_label(-1 * actual_damage) # spawn negative


func _spawn_damage_label(amount: int) -> void:
    var label: Node3D = DAMAGE_LABEL_SCENE.instantiate()
    get_parent().add_child(label)
    label.global_position = global_position + Vector3(0, 0.8, 0)
    label.set_damage(amount)
    
