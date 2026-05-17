extends Control

signal new_game_requested

@onready var new_game_button: Button = $New_Game_Button_Control/New_Game_Button


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_button_pressed)


func _on_new_game_button_pressed() -> void:
	new_game_requested.emit()
