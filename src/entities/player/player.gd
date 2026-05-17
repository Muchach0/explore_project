class_name Player
extends CharacterBody3D

## Player-controlled character. Handles 8-directional movement and animation.

const SPEED: float = 5.0

@onready var animation_player: AnimationPlayer = $SubViewport/Player2DModel/AnimationPlayer

var selected_entity: Node3D = null

# Skills available to the player
# Index 0: SimpleShootSkill (left click)
# Index 1: AOEShootSkill (right click)
@export var default_skills: Array[Skill] = []
var skills: Array[Skill] = []

var _casting: bool = false
var _pending_skill: Skill = null
var _pending_target: Vector2 = Vector2.ZERO
@onready var _cast_timer: Timer = $CastTimer
var inventory: Inventory = Inventory.new()


# Experience related variables
# @export var attribute_data: AttributeData
# @export var class_data: ClassData
# @export var level_table: LevelTable
@export var level : int = 1 # The current level of the player
@export var current_xp : int = 0 # The current XP of the player
@export var skill_points : int = 0 # The current skill points of the player


func _ready() -> void:
    animation_player.play("idle")
    EventBus.entity_selected.connect(_on_entity_selected)
    EventBus.skill_slot_pressed.connect(_use_skill)
    # Initialize default skills if not already set
    if skills.size() == 0:
        for skill in default_skills:
            print("player.gd() - ready() - default_skills: " + skill.skill_name)
            skills.append(skill.duplicate())

    EventBus.attach_inventory_to_ui.emit.call_deferred(inventory)
    EventBus.attach_skills_to_ui.emit.call_deferred(skills)
    EventBus.xp_gathered.connect(add_xp)

    _cast_timer.timeout.connect(_on_cast_complete)


func _on_entity_selected(entity: Node3D) -> void:
    selected_entity = entity


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1: _use_skill(0)
        match event.keycode:
            KEY_2: _use_skill(1)
        match event.keycode:
            KEY_3: _use_skill(2)
        match event.keycode:
            KEY_4: _use_skill(3)


func _use_skill(index: int) -> void:
    print("player.gd - _use_skill() - with index: " + str(index))
    if index >= skills.size() or _casting:
        return
    var skill: Skill = skills[index]
    if skill.is_on_cooldown():
        return
    var mouse_pos := get_viewport().get_mouse_position()
    if skill.cast_time > 0.0:
        _casting = true
        _pending_skill = skill
        _pending_target = mouse_pos
        _cast_timer.wait_time = skill.cast_time
        _cast_timer.start()
        EventBus.cast_started.emit(skill.skill_name, skill.cast_time)
        play_animation("cast", true)
    else:
        skill.execute(self, mouse_pos)



func _on_cast_complete() -> void:
    _casting = false
    play_animation("cast", false)
    if _pending_skill != null:
        _pending_skill.execute(self, _pending_target)
        _pending_skill = null
    EventBus.cast_finished.emit()


func _physics_process(_delta: float) -> void:
    var input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = Vector3(input.x, 0.0, input.y) * SPEED
    move_and_slide()
    _update_animation(velocity)


func _update_animation(vel: Vector3) -> void:
    if _casting:
        return
    animation_player.play("idle" if is_zero_approx(vel.length()) else "walk", 0.05)


func play_animation(animation_name: String, should_play: bool) -> void:
    if not should_play:
        print("player.gd - play_animation - casting RESET animation")
        animation_player.play("RESET")
        return
    if animation_player.has_animation(animation_name):
        animation_player.play(animation_name)
        print("player.gd - play_animation - playing animation: " + animation_name)
    else:
        print("player.gd - play_animation - no animation: " + animation_name)


#region Experience related functions

# func _check_level_up() -> void:
# 	var levels_gained := 0
# 	while current_xp >= level_table.xp_to_next(level) and level < level_table.max_level:
# 		var xp_required = level_table.xp_to_next(level)
# 		current_xp -= xp_required
# 		level += 1
# 		levels_gained += 1
#
# 		var res = class_data.apply_level_up(attribute_data, 1)
# 		if res.has("skill_points_awarded"):
# 			skill_points += int(res["skill_points_awarded"])
#
# 		EventBus.leveled_up.emit(level, 1, res.get("skill_points_awarded", 0))
#
# 	if levels_gained > 1:
# 		EventBus.leveled_up.emit(level, levels_gained, skill_points)
# 	EventBus.xp_changed.emit(current_xp, level_table.xp_to_next(level))

func add_xp(amount: int) -> void:
    if amount <= 0:
        return
    current_xp += amount
    # EventBus.xp_changed.emit(current_xp, level_table.xp_to_next(level))
    # _check_level_up()
#endregion
