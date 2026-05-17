class_name GameManager
extends Node

signal level_started(level_number: int)
signal intermediate_screen_started(completed_level_number: int)
signal game_completed

const DEFAULT_LEVEL_PATHS: Array[String] = [
	"res://levels/level_1_3d.tscn",
	"res://levels/level_2_3d.tscn",
	"res://levels/level_3_3d.tscn",
]
const DEFAULT_PLAYER_SCENE_PATH: String = "res://src/entities/player/player.tscn"
const DEFAULT_MAIN_MENU_SCENE_PATH: String = "res://levels/main_menu.tscn"
const DEFAULT_INTERMEDIATE_SCREEN_SCENE_PATH: String = "res://levels/choice_upgrade_menu.tscn"

@export_file("*.tscn") var main_menu_scene_path: String = DEFAULT_MAIN_MENU_SCENE_PATH
@export_file("*.tscn") var player_scene_path: String = DEFAULT_PLAYER_SCENE_PATH
@export_file("*.tscn") var intermediate_screen_scene_path: String = DEFAULT_INTERMEDIATE_SCREEN_SCENE_PATH
@export var level_scene_paths: Array[String] = DEFAULT_LEVEL_PATHS
@export var show_main_menu_on_start: bool = true

var current_level_index: int = -1
var current_level: Node = null
var player: Player = null

var _enemies_alive: int = 0
var _level_completion_pending: bool = false
var _main_menu: Control = null
var _intermediate_screen: Control = null


func _ready() -> void:
	if not EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.connect(_on_enemy_died)

	if show_main_menu_on_start:
		show_main_menu()
	else:
		start_game()


func show_main_menu() -> void:
	_clear_current_level()
	_clear_current_screen()
	_clear_main_menu()

	var main_menu_scene := _load_packed_scene(main_menu_scene_path)
	if main_menu_scene == null:
		push_warning("GameManager: Main menu scene not found: %s" % main_menu_scene_path)
		start_game()
		return

	_main_menu = main_menu_scene.instantiate() as Control
	if _main_menu == null:
		push_warning("GameManager: Main menu scene root must extend Control.")
		start_game()
		return

	add_child(_main_menu)
	if _main_menu.has_signal("new_game_requested"):
		_main_menu.new_game_requested.connect(start_game)


func start_game() -> void:
	_clear_main_menu()
	_reset_persistent_party_state()
	current_level_index = -1
	load_next_level()


func load_next_level() -> void:
	var next_level_index := current_level_index + 1
	if next_level_index >= level_scene_paths.size():
		_complete_game()
		return

	_clear_current_screen()
	_clear_current_level()

	var level_scene := _load_packed_scene(level_scene_paths[next_level_index])
	if level_scene == null:
		push_warning("GameManager: Level scene not found: %s" % level_scene_paths[next_level_index])
		_complete_game()
		return

	current_level_index = next_level_index
	current_level = level_scene.instantiate()
	add_child(current_level)

	var embedded_player_transform := _remove_embedded_players(current_level)
	var embedded_allies := _remove_embedded_allies(current_level)

	player = _spawn_player(current_level, embedded_player_transform)
	_spawn_allies(current_level, embedded_allies)
	_track_level_enemies()

	EventBus.update_level_number.emit(current_level_index + 1)
	level_started.emit(current_level_index + 1)


func complete_current_level() -> void:
	if current_level_index < 0:
		return

	_capture_persistent_party_state()

	if current_level_index >= level_scene_paths.size() - 1:
		_complete_game()
		return

	_show_intermediate_screen()


func _track_level_enemies() -> void:
	_enemies_alive = 0
	_level_completion_pending = false

	if current_level == null:
		return

	for node in current_level.find_children("*", "", true, false):
		if not node.is_in_group("enemy"):
			continue

		_enemies_alive += 1

	if _enemies_alive <= 0:
		_complete_level_if_all_enemies_dead.call_deferred()


func _on_enemy_died(enemy: Node) -> void:
	if current_level == null or _level_completion_pending:
		return
	if not current_level.is_ancestor_of(enemy):
		return

	_enemies_alive -= 1
	if _enemies_alive <= 0:
		_complete_level_if_all_enemies_dead.call_deferred()


func _complete_level_if_all_enemies_dead() -> void:
	if _level_completion_pending or current_level == null or _enemies_alive > 0:
		return

	_level_completion_pending = true
	complete_current_level()


func choose_player_upgrade(upgrade: Upgrade) -> void:
	upgrade.apply_upgrade() # Applying the upgrade
	load_next_level()


func reload_current_level() -> void:
	if current_level_index < 0:
		start_game()
		return

	_capture_persistent_party_state()
	current_level_index -= 1
	load_next_level()


func _spawn_player(parent: Node, fallback_spawn_transform: Transform3D = Transform3D.IDENTITY) -> Player:
	var player_state := _get_persistent_player_state()
	var party_player_scene_path: String = player_state.get("scene_path", player_scene_path)
	var player_scene := _load_packed_scene(party_player_scene_path)
	if player_scene == null:
		push_warning("GameManager: Player scene not found: %s" % party_player_scene_path)
		return null

	var spawned_player := player_scene.instantiate() as Player
	if spawned_player == null:
		push_warning("GameManager: Player scene root must extend Player.")
		return null

	if not player_state.is_empty():
		_apply_player_state(spawned_player, player_state)

	var spawn_point := _find_spawn_point(parent)
	parent.add_child(spawned_player)
	if spawn_point != null:
		spawned_player.global_position = spawn_point.global_position
	else:
		spawned_player.global_transform = fallback_spawn_transform

	return spawned_player


func _spawn_allies(parent: Node, fallback_allies: Array[Dictionary]) -> void:
	var spawn_states: Array = _get_persistent_allies_state()
	if spawn_states.is_empty():
		return

	var ally_spawn_points := _find_ally_spawn_points(parent)
	for index in spawn_states.size():
		var ally_state: Dictionary = spawn_states[index]
		var ally_scene_path: String = ally_state.get("scene_path", "")
		var ally_scene := _load_packed_scene(ally_scene_path)
		if ally_scene == null:
			push_warning("GameManager: Ally scene not found: %s" % ally_scene_path)
			continue

		var ally := ally_scene.instantiate() as Node3D
		if ally == null:
			push_warning("GameManager: Ally scene root must extend Node3D: %s" % ally_scene_path)
			continue

		_apply_ally_state(ally, ally_state)
		parent.add_child(ally)
		if index < ally_spawn_points.size():
			ally.global_transform = ally_spawn_points[index].global_transform
		elif index < fallback_allies.size():
			ally.global_transform = fallback_allies[index].get("spawn_transform", Transform3D.IDENTITY)
		elif ally_state.has("spawn_transform"):
			ally.global_transform = ally_state["spawn_transform"]
		elif player != null:
			ally.global_position = player.global_position + Vector3(index + 1, 0.0, 0.0)

		if index < fallback_allies.size() and fallback_allies[index].has("long_term_target_path"):
			var target := parent.get_node_or_null(fallback_allies[index]["long_term_target_path"]) as Node3D
			_set_node_property(ally, "long_term_target", target)
		elif player != null:
			_set_node_property(ally, "long_term_target", player)

		if ally.has_method("find_closest_target"):
			ally.call_deferred("find_closest_target")


func _show_intermediate_screen() -> void:
	_clear_current_level()

	if intermediate_screen_scene_path != "":
		var screen_scene := _load_packed_scene(intermediate_screen_scene_path)
		if screen_scene != null:
			_intermediate_screen = screen_scene.instantiate() as Control

	if _intermediate_screen == null:
		_intermediate_screen = _build_default_intermediate_screen()

	add_child(_intermediate_screen)
	
	EventBus.upgrade_chosen.connect(choose_player_upgrade)
	
	intermediate_screen_started.emit(current_level_index + 1)


func _build_default_intermediate_screen() -> Control:
	var root := Control.new()
	root.name = "IntermediateScreen"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 220)
	center.add_child(panel)

	var choices := VBoxContainer.new()
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 12)
	panel.add_child(choices)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "Choose your upgrade"
	choices.add_child(title)

	_add_choice_button(choices, "More health", "health")
	_add_choice_button(choices, "More speed", "speed")
	_add_choice_button(choices, "Stronger heal", "heal")

	return root


func _add_choice_button(parent: Node, label: String, choice_id: String) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(choose_player_upgrade.bind(choice_id))
	parent.add_child(button)


func _find_spawn_point(root: Node) -> Node3D:
	var spawn_point := root.find_child("PlayerSpawn", true, false) as Node3D
	if spawn_point != null:
		return spawn_point
	return root.find_child("SpawnPoint", true, false) as Node3D


func _find_ally_spawn_points(root: Node) -> Array[Node3D]:
	var spawn_points: Array[Node3D] = []
	for node in root.find_children("*", "", true, false):
		if node is Node3D and (node.name.begins_with("AllySpawn") or node.name.begins_with("PartySpawn")):
			spawn_points.append(node as Node3D)
	return spawn_points


func _remove_embedded_players(root: Node) -> Transform3D:
	var fallback_spawn_transform := Transform3D.IDENTITY
	var found_spawn_transform := false
	var embedded_players: Array[Node] = []

	for node in root.find_children("*", "", true, false):
		if not (node is Player or node.is_in_group("player")):
			continue

		if not found_spawn_transform and node is Node3D:
			fallback_spawn_transform = (node as Node3D).global_transform
			found_spawn_transform = true

		embedded_players.append(node)

	for embedded_player in embedded_players:
		embedded_player.free()

	return fallback_spawn_transform


func _remove_embedded_allies(root: Node) -> Array[Dictionary]:
	var embedded_allies: Array[Node] = []
	var ally_states: Array[Dictionary] = []

	for node in root.find_children("*", "", true, false):
		if not node.is_in_group("ally"):
			continue
		embedded_allies.append(node)
		if node is Node3D:
			var ally_state := _capture_ally_state(node as Node3D)
			ally_state["spawn_transform"] = (node as Node3D).global_transform
			var long_term_target := _get_node_property(node, "long_term_target", null) as Node3D
			if long_term_target != null and root.is_ancestor_of(long_term_target):
				ally_state["long_term_target_path"] = root.get_path_to(long_term_target)
			ally_states.append(ally_state)

	for embedded_ally in embedded_allies:
		embedded_ally.free()

	return ally_states


func _capture_persistent_party_state() -> void:
	if player != null:
		PartyStats.stats["player"] = _capture_player_state(player)

	PartyStats.stats["allies"] = []
	if current_level == null:
		return

	for node in current_level.find_children("*", "", true, false):
		if node is Node3D and node.is_in_group("ally"):
			PartyStats.stats["allies"].append(_capture_ally_state(node as Node3D))


func _capture_player_state(source_player: Player) -> Dictionary:
	return {
		"scene_path": source_player.scene_file_path if source_player.scene_file_path != "" else player_scene_path,
		"default_skills": _duplicate_resource_array(source_player.default_skills),
		"skills": _duplicate_resource_array(source_player.skills),
		"inventory": _duplicate_resource(source_player.inventory),
		"level": source_player.level,
		"current_xp": source_player.current_xp,
		"skill_points": source_player.skill_points,
	}


func _apply_player_state(target_player: Player, state: Dictionary) -> void:
	# target_player.default_skills = _to_skill_array(state.get("default_skills", []))
	target_player.skills = _to_skill_array(state.get("skills", []))
	var inventory: Variant = state.get("inventory", null)
	target_player.inventory = inventory if inventory is Inventory else Inventory.new()
	target_player.level = state.get("level", target_player.level)
	target_player.current_xp = state.get("current_xp", target_player.current_xp)
	target_player.skill_points = state.get("skill_points", target_player.skill_points)


func _capture_ally_state(ally: Node3D) -> Dictionary:
	return {
		"scene_path": ally.scene_file_path,
		"max_health": _get_node_property(ally, "max_health", 100),
		"current_health": _get_node_property(ally, "current_health", _get_node_property(ally, "max_health", 100)),
		"target_group": _get_node_property(ally, "target_group", "enemy"),
		"aggro_speed": _get_node_property(ally, "aggro_speed", 4.0),
		"walk_speed": _get_node_property(ally, "walk_speed", 3.0),
		"wander_speed": _get_node_property(ally, "wander_speed", 2.0),
		"attack_range": _get_node_property(ally, "attack_range", 1.5),
		"attack_damage": _get_node_property(ally, "attack_damage", 10),
		"attack_cooldown": _get_node_property(ally, "attack_cooldown", 1.5),
		"attack_active_duration": _get_node_property(ally, "attack_active_duration", 0.3),
		"idle_duration_min": _get_node_property(ally, "idle_duration_min", 2.0),
		"idle_duration_max": _get_node_property(ally, "idle_duration_max", 5.0),
		"wander_duration_min": _get_node_property(ally, "wander_duration_min", 1.5),
		"wander_duration_max": _get_node_property(ally, "wander_duration_max", 4.0),
		"stop_distance": _get_node_property(ally, "stop_distance", 2.0),
		"give_up_range": _get_node_property(ally, "give_up_range", 20.0),
		"follow_range": _get_node_property(ally, "follow_range", 0.0),
		"despawn_delay": _get_node_property(ally, "despawn_delay", 3.0),
	}


func _apply_ally_state(ally: Node3D, state: Dictionary) -> void:
	var health_after_ready: int = state.get("current_health", _get_node_property(ally, "max_health", 100))
	for property_name in state.keys():
		if property_name in ["scene_path", "spawn_transform", "long_term_target_path", "current_health"]:
			continue
		_set_node_property(ally, property_name, state[property_name])

	ally.ready.connect(
		func():
			_set_node_property(ally, "current_health", health_after_ready)
			var health_component: Variant = ally.get("health_component")
			if health_component != null and health_component.has_method("update_life_bar"):
				health_component.update_life_bar(health_after_ready)
	)


func _duplicate_resource_array(resources: Array) -> Array:
	var duplicates: Array = []
	for resource in resources:
		duplicates.append(_duplicate_resource(resource))
	return duplicates


func _to_skill_array(resources: Array) -> Array[Skill]:
	var skills: Array[Skill] = []
	for resource in resources:
		if resource is Skill:
			skills.append(resource)
	return skills


func _duplicate_resource(resource: Variant) -> Variant:
	if resource is Resource:
		return resource.duplicate(true)
	return resource


func _get_node_property(node: Node, property_name: String, fallback: Variant) -> Variant:
	for property in node.get_property_list():
		if property.name == property_name:
			return node.get(property_name)
	return fallback


func _set_node_property(node: Node, property_name: String, value: Variant) -> void:
	for property in node.get_property_list():
		if property.name == property_name:
			node.set(property_name, value)
			return


func _get_persistent_player_state() -> Dictionary:
	return PartyStats.stats.get("player", {})


func _get_persistent_allies_state() -> Array:
	return PartyStats.stats.get("allies", [])


func _reset_persistent_party_state() -> void:
	PartyStats.reset_stats()


func _clear_current_level() -> void:
	if current_level != null:
		current_level.queue_free()
		current_level = null
	player = null
	_enemies_alive = 0
	_level_completion_pending = false


func _clear_current_screen() -> void:
	if _intermediate_screen != null:
		_intermediate_screen.queue_free()
		_intermediate_screen = null


func _clear_main_menu() -> void:
	if _main_menu != null:
		_main_menu.queue_free()
		_main_menu = null


func _complete_game() -> void:
	_clear_current_level()
	_clear_current_screen()
	game_completed.emit()


func _load_packed_scene(scene_path: String) -> PackedScene:
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return null
	return load(scene_path) as PackedScene
