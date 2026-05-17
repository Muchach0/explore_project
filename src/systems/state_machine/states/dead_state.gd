class_name DeadState
extends State

func enter() -> void:
	actor.velocity = Vector3.ZERO
	var collision := actor.get_node_or_null("CollisionShape3D")
	if collision:
		collision.set_deferred("disabled", true)
	actor.get_tree().create_timer(actor.despawn_delay).timeout.connect(actor.queue_free)
	actor.play_animation("dead", true)
