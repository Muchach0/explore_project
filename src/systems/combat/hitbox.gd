class_name Hitbox 
extends Area3D

############################################################
# TRUE: Hitbox component - Take damage. 
# This gets hit by the hurtbox.
############################################################


func _ready() -> void:
    area_entered.connect(on_area_entered)


func on_area_entered(hurtbox: Node):
    if hurtbox == null or not hurtbox is Hurtbox:
        return
    if _is_self_hurtbox(hurtbox):
        return
    if _is_same_combat_group(hurtbox):
        return

    if owner.has_method("take_damage"):
        # print_debug("Hitbox.gd - on_area_entered - owner has a take_damage method")
        owner.take_damage(hurtbox.damage, hurtbox.from_player_id)
        hurtbox.attack_landed()
    if hurtbox.should_disapear_on_hit:
        hurtbox.get_parent().queue_free()


func _is_self_hurtbox(hurtbox: Hurtbox) -> bool:
    var hurtbox_source := _get_hurtbox_source(hurtbox)
    if hurtbox_source == owner:
        return true

    return false


func _is_same_combat_group(hurtbox: Hurtbox) -> bool:
    var hurtbox_source := _get_hurtbox_source(hurtbox)
    if hurtbox_source == null or owner == null:
        return false

    for group in EventBus.COMBAT_GROUPS:
        if owner.is_in_group(group) and hurtbox_source.is_in_group(group):
            return true

    return false


func _get_hurtbox_source(hurtbox: Hurtbox) -> Node:
    if hurtbox.owner != null:
        return hurtbox.owner

    var node := hurtbox.get_parent()
    while node != null:
        if node.has_method("take_damage"):
            return node
        node = node.get_parent()

    return null
