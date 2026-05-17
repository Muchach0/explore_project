extends Node

# File that will hold the variable of the party stats.

const DEFAULT_PLAYER_SCENE_PATH: String = "res://src/entities/player/player.tscn"
const DEFAULT_ALLY_SCENE_PATH: String = "res://src/entities/npc/allies/ally_tomatoe_1.tscn"
const DEFAULT_HEAL_SKILL: Skill = preload("res://resources/skills/healskill.tres")

var stats: Dictionary = _build_default_stats()


func reset_stats() -> void:
    stats = _build_default_stats()


func _build_default_stats() -> Dictionary:
    return {
        "player": {
        "scene_path": DEFAULT_PLAYER_SCENE_PATH,
        # "default_skills": [DEFAULT_HEAL_SKILL, DEFAULT_HEAL_SKILL, DEFAULT_HEAL_SKILL],
        "skills": [],
        "inventory": null,
        "level": 1,
        "current_xp": 0,
        "skill_points": 0,
    },
        "allies": [
            {
                "scene_path": DEFAULT_ALLY_SCENE_PATH,
                "spawn_transform": Transform3D(Basis.IDENTITY, Vector3(-1.7356415, 0.0, -1.2664795)),
                "max_health": 100,
                "current_health": 100,
                "target_group": "enemy",
                "aggro_speed": 4.0,
                "walk_speed": 3.0,
                "wander_speed": 2.0,
                "attack_range": 0.75,
                "attack_damage": 10,
                "attack_cooldown": 1.0,
                "attack_active_duration": 0.3,
                "idle_duration_min": 2.0,
                "idle_duration_max": 5.0,
                "wander_duration_min": 1.5,
                "wander_duration_max": 4.0,
                "stop_distance": 2.0,
                "give_up_range": 20.0,
                "follow_range": 0.0,
                "despawn_delay": 3.0,
            }
        ],
    }
