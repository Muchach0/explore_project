class_name Add_Max_Health_Ally_Upgrade extends Upgrade

## Apply the upgrade. Override this in derived classes.
func apply_upgrade() -> void:
    print("add_ally.gd() - Apply the upgrade to add max health to all allies in the party")
    for ally in PartyStats.stats["allies"]:
        ally["max_health"] = ally["max_health"] + 50
