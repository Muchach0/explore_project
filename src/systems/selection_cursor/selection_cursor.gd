extends Node3D

@onready var _sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	_do_selection(mouse_event.position)

func _do_selection(screen_pos: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	var end := origin + direction * 1000.0

	var query := PhysicsRayQueryParameters3D.create(origin, end)
	var space_state := get_world_3d().direct_space_state
	var result: Dictionary = space_state.intersect_ray(query)

	if result.is_empty():
		return

	var collider := result["collider"] as CollisionObject3D
	if collider == null or not collider.is_in_group("selectable"):
		return

	var target_pos: Vector3 = collider.global_position
	global_position = Vector3(target_pos.x, target_pos.y + 0.05, target_pos.z)
	visible = true
	EventBus.entity_selected.emit(collider)
