extends Node2D
class_name HealthComponent

@onready var life_ui_bar = $LifeUIBar

var current_health: float = 0.0
var max_health: float = 0.0

func init_life_bar(health):
	max_health = health
	current_health = health
	life_ui_bar.max_value = health
	life_ui_bar.value = health

func update_life_bar(new_health: float) -> void:
	current_health = new_health
	life_ui_bar.value = new_health
