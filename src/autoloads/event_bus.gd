extends Node

# Global event bus — connect signals here, not via direct node references.
# Emit from anywhere; listen from anywhere.

signal add_player
# Maybe need to add all the other signals

signal attach_inventory_to_ui

# Skills
signal leveled_up
signal one_skill_level_up
signal attach_skills_to_ui(skills: Array[Skill])
signal skills_changed
signal skill_slot_pressed(skill_index: int)


signal update_level_number

# 
signal show_inventory_ui
signal xp_changed
signal player_died
signal xp_gathered

# Selection
signal entity_selected(entity: Node3D)
