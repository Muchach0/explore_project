class_name Add_Ally extends Upgrade

## Apply the upgrade. Override this in derived classes.
func apply_upgrade() -> void:
    print("add_ally.gd() - Apply the upgrade to add an ally to the party")
    var new_ally: Dictionary = PartyStats.stats["allies"][0].duplicate()
    # new_ally["spawn_transform"] = PartyStats.stats["allies"][0]["spawn_transform"]
    PartyStats.stats["allies"].append(new_ally)
