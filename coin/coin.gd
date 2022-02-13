class_name Coin
extends Area2D

var taken = false

func _on_body_enter(body):
	if not taken and body is Player2:
		taken = true
		(body as Player2).set_coin_collected()
		($AnimationPlayer as AnimationPlayer).play("taken")
