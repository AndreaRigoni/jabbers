extends Control

onready var player      = get_node("../..")
onready var coins_label = $HBoxContainer/VBoxContainer/HBoxContainer/NinePatchRect/bg/coin_label
onready var jab_label   = $HBoxContainer/NinePatchRect2/bg/jab_label
onready var jab_bar     = $HBoxContainer/NinePatchRect2/NinePatchRect/TextureProgress
onready var cas_label   = $HBoxContainer/VBoxContainer/HBoxContainer/NinePatchRect4/bg/cas_label

# Called when the node enters the scene tree for the first time.
func update():
	update_collected_coins()
	update_casualties()
	update_available_jabs()
	
func update_collected_coins():
	coins_label.text = str(player.collected_coins)

func update_casualties():
	cas_label.text = str(player.dead_patients)

func update_available_jabs():
	jab_label.text = str(player.jabs)
	jab_bar.value = int(player.jabs *100 / player.MAX_JABS)



func _on_Player2_coin_collected():
	update_collected_coins()
	
func _on_Player2_shot_bullet():
	update_available_jabs()

func _on_Player2_jab_collected():
	update_available_jabs()

func _on_Player2_patient_killed():
	update_casualties()
	
