class_name Jab
extends Area2D

var taken = false

func _on_body_enter(body):
	if not taken and body is Player2:
		taken = true
		(body as Player2).set_jab_collected()
		($AnimationPlayer as AnimationPlayer).play("taken")
