class_name Upgrade
extends Resource
## Base class for all game upgrades.
## Upgrades are resources that describe an improvement and know how to apply it.

## The name of the upgrade.
@export var upgrade_name: String = "Unnamed Upgrade"

## A short description of what the upgrade does.
@export_multiline var description: String = ""

## The icon displayed for the upgrade.
@export var icon: Texture2D = AtlasTexture.new()


## Apply the upgrade. Override this in derived classes.
func apply_upgrade() -> void:
	push_error("Upgrade.apply_upgrade() called on base class - override this method!")
	pass
