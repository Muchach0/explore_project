class_name NPC
extends CharacterBody3D
# Global script for both the enemies and the allies

const DAMAGE_LABEL_SCENE: PackedScene = preload("res://src/ui/health_and_damage_labels/DamageLabel.tscn")

@export_group("Health")
@export var max_health: int = 100
var current_health: int

@export_group("Aggro")
## "player" for enemies; "enemy" for allies.
@export var target_group: String = "player"

@export_group("Movement")
@export var aggro_speed: float = 4.0
@export var walk_speed: float = 3.0
@export var wander_speed: float = 2.0

@export_group("Attack")
## Deprecated: combat now attacks when the hurtbox touches a hitbox.
@export var attack_range: float = 1.5
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.5
## How long the hurtbox collision stays active per swing.
@export var attack_active_duration: float = 0.3

@export_group("Idle & Wander")
@export var idle_duration_min: float = 2.0
@export var idle_duration_max: float = 5.0
@export var wander_duration_min: float = 1.5
@export var wander_duration_max: float = 4.0

@export_group("Walking")
@export var stop_distance: float = 2.0
@export var give_up_range: float = 20.0
## When > 0, idle transitions to WalkingState if the player enters this radius but stays outside aggro_range.
@export var follow_range: float = 0.0

@export_group("Dead")
@export var despawn_delay: float = 3.0

@onready var health_component: HealthComponent = $SubViewport/Model2D/HealthComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var sprite: Sprite3D = $Sprite3D
@onready var animation_player: AnimationPlayer = $SubViewport/Model2D/AnimationPlayer
@onready var hurtbox: Hurtbox = $CollisionShape3D/Hurtbox
@onready var aggro_area: Area3D = get_node_or_null("AggroArea3D")
@onready var particle_heal: GPUParticles3D = get_node_or_null("ParticleHeal")
@onready var _subviewport: SubViewport = $SubViewport
@onready var _model_2d: Node2D = $SubViewport/Model2D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _is_attacking: bool = false
var _is_hurtbox_active: bool = false
var _hurtbox_default_pos: Vector3 = Vector3.ZERO
var _is_dead: bool = false

## Long-term destination/subject this NPC walks toward outside combat.
@export var long_term_target: Node3D = null
## Short-term aggro target this NPC attacks while in combat.
var short_term_target: Node3D = null


func _ready() -> void:
    current_health = max_health
    health_component.init_life_bar(max_health)
    if hurtbox:
        hurtbox.damage = attack_damage
        set_hurtbox_active(false, false)
        _hurtbox_default_pos = hurtbox.position
    if aggro_area:
        aggro_area.body_entered.connect(_on_aggro_area_body_entered)


func _physics_process(_delta: float) -> void:
    if not is_instance_valid(short_term_target):
        short_term_target = null
    if not is_instance_valid(long_term_target):
        long_term_target = null
    var facing_target := short_term_target if short_term_target else long_term_target
    if not facing_target:
        return
    _update_facing(facing_target)


# Function to update the facing.
# The collision shape always face the active target
# The sprite is flipped only when necessary
func _update_facing(facing_target: Node3D) -> void:
    collision_shape.look_at(facing_target.global_position, Vector3.UP)
    var direction = facing_target.global_position - global_position
    if direction.x < 0:
         flip_sprite(true)
    else:
        flip_sprite(false)
func flip_sprite(should_flip_sprite: bool) -> void:
    sprite.flip_h = should_flip_sprite



func _on_aggro_area_body_entered(body: Node3D) -> void:
    if body == self or not body.is_in_group(target_group):
        return
    if body is NPC and body.current_health <= 0:
        return
    short_term_target = body
    var state_name := state_machine.current_state.name
    if state_name in ["CombatState", "DeadState"]:
        return
    
    state_machine.transition_to("CombatState")


## Returns the closest live node in target_group currently inside the AggroArea3D.
## Updates short_term_target, or clears it when no valid aggro target exists.
func find_closest_short_term_target() -> Node3D:
    if not aggro_area:
        short_term_target = null
        return null
    var closest: Node3D = null
    var min_dist := INF
    for body: Node3D in aggro_area.get_overlapping_bodies():
        if body == self or not body.is_in_group(target_group):
            continue
        if body is NPC and body.current_health <= 0:
            continue
        var d := global_position.distance_to(body.global_position)
        if d < min_dist:
            min_dist = d
            closest = body
    short_term_target = closest
    return closest


func find_closest_target() -> Node3D:
    return find_closest_short_term_target()


func heal(amount: int) -> void:
    _spawn_damage_label(amount)
    _emit_heal_particles()
    var actual_heal := mini(amount, max_health - current_health)
    if actual_heal <= 0:
        return
    current_health += actual_heal
    health_component.update_life_bar(current_health)
    


func take_damage(amount: int, _from_player_id: int = -1) -> void:
    if _is_dead:
        return
    var actual_damage := mini(amount, current_health)
    if actual_damage <= 0:
        return
    current_health -= actual_damage
    health_component.update_life_bar(current_health)
    _spawn_damage_label(-1 * actual_damage)
    if current_health <= 0:
        _is_dead = true
        if is_in_group("enemy"):
            EventBus.enemy_died.emit(self)
        state_machine.transition_to("DeadState")


func attack() -> void:
    if _is_attacking:
        return
    _is_attacking = true
    play_animation("attack", true)
    get_tree().create_timer(attack_active_duration).timeout.connect(
        func():
            _is_attacking = false
    )


func set_hurtbox_active(is_active: bool, deferred: bool = true) -> void:
    _is_hurtbox_active = is_active
    if not is_instance_valid(hurtbox):
        return
    hurtbox.damage = attack_damage
    if deferred:
        hurtbox.collision_shape.set_deferred("disabled", not is_active)
    else:
        hurtbox.collision_shape.disabled = not is_active


func is_hurtbox_active() -> bool:
    return _is_hurtbox_active


func play_animation(animation_name: String, should_play: bool) -> void:
    if not should_play:
        animation_player.play("RESET")
        return
    if animation_player.has_animation(animation_name):
        animation_player.play(animation_name)


func _spawn_damage_label(amount: int) -> void:
    var label: Node3D = DAMAGE_LABEL_SCENE.instantiate()
    get_parent().add_child(label)
    label.global_position = global_position + Vector3(0, 0.8, 0)
    label.set_damage(amount)


func _emit_heal_particles() -> void:
    if not is_instance_valid(particle_heal):
        return
    particle_heal.restart()
