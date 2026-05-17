class_name StateMachine
extends Node

## Finite state machine. Add State child nodes; the machine wires them up and
## drives update/physics_update each frame.

@export var initial_state_name: String = "IdleState"

var current_state: State
var _states: Dictionary = {}

func _ready() -> void:
	await owner.ready
	var actor := owner as NPC
	for child in get_children():
		if child is State:
			_states[child.name] = child
			child.actor = actor
			child.transitioned.connect(_on_child_transitioned)
	if _states.has(initial_state_name):
		current_state = _states[initial_state_name]
		current_state.enter()
	else:
		push_warning("StateMachine: initial state '%s' not found." % initial_state_name)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(state_name: String) -> void:
	if not _states.has(state_name):
		push_warning("StateMachine: unknown state '%s'" % state_name)
		return
	if current_state:
		current_state.exit()
	current_state = _states[state_name]
	current_state.enter()

func _on_child_transitioned(_from: State, to_name: String) -> void:
	transition_to(to_name)
