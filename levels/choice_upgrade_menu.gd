extends Control

signal upgrade_chosen(choice_id: String)

# Upgrades available and that will be choosen randomly
@export var upgrade_availables: Array[Upgrade] = []

# ordered list of available upgrades for the player to choose from
@onready var upgrades_choosen_randomly_list: Array[Upgrade] = []

@onready var upgrade_buttons: Array[Button] = [
    $Three_Column_Control/HBoxContainer/Button1,
    $Three_Column_Control/HBoxContainer/Button2,
    $Three_Column_Control/HBoxContainer/Button3,
]


func _ready() -> void:
    for index in upgrade_buttons.size():
        var rand_index_upgrade = randi_range(0, upgrade_availables.size() - 1)
        var upgrade_choosen_randomly = upgrade_availables[rand_index_upgrade]
        
        upgrades_choosen_randomly_list.append(upgrade_choosen_randomly)

        var button := upgrade_buttons[index]
        button.icon = upgrade_choosen_randomly.icon
        button.text = upgrade_choosen_randomly.upgrade_name + "\n" + upgrade_choosen_randomly.description
        
        button.pressed.connect(_on_upgrade_button_pressed.bind("upgrade_%d" % (index)))


func _on_upgrade_button_pressed(choice_id: String) -> void:
    EventBus.upgrade_chosen.emit(upgrades_choosen_randomly_list[int(choice_id)])
