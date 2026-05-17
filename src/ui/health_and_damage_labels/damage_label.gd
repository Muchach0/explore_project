extends Node3D

@export var gravity := Vector3(0, -9.8, 0)
var _velocity := Vector3.ZERO


func _ready():
    _velocity = Vector3(randf_range(-0.5, 0.5), 2.0, 0.0)

func _physics_process(delta):
    _velocity += gravity * delta
    position += _velocity * delta


func set_damage(damage):
    if damage >= 0:
        $Label3D.text = "+" + str(damage)
        $Label3D.modulate = Color.GREEN
    else:
        $Label3D.text = str(damage)
        $Label3D.modulate = Color.html("#ea4f36")
    $AnimationPlayer.play("show")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
    if anim_name == "show":
        queue_free()
