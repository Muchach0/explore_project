class_name State
extends Node

## Base class for all entity states.
## Subclasses override enter/exit/update/physics_update as needed.

signal transitioned(from_state: State, to_state_name: String)

var actor: NPC

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

## Returns the nearest node in the "player" group, or null when none exist.
## Requires the player scene to belong to the "player" group.
func _find_closest_player() -> Node3D:
	return _find_closest_in_group("player")

## Returns the nearest live node in the given group, or null when none exist.
func _find_closest_in_group(group: String) -> Node3D:
	var closest: Node3D = null
	var min_dist := INF
	for p: Node3D in actor.get_tree().get_nodes_in_group(group):
		var d := actor.global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			closest = p
	return closest
