class_name Patient
extends RigidBody2D

const WALK_SPEED = 50

enum State {
	WALKING,
	DYING,
	IMMUNE,
}

var state = State.WALKING

var direction = -1
var anim = ""

var Bullet = preload("res://player/bullet.gd")

onready var rc_left = $RaycastLeft
onready var rc_right = $RaycastRight


var rng = RandomNumberGenerator.new()
var will_die

var james1 = preload("res://patient/sheet-pixelchar03-james.png")
var james2 = preload("res://patient/sheet-pixelchar03-james2.png")

onready var player_texture = get_node("Sprite")

signal is_dead


func random_player():
	var image_players = [james1, james2]
	var name = image_players[randi() % image_players.size()]
	($Sprite as Sprite).texture = (name)


func _ready():
	random_player()
	rng.randomize()
	will_die = (rng.randi()%100 < 30)
	connect('is_dead', get_tree().get_current_scene().get_node('Player2'), '_on_Patient_is_dead')
	
	

func _integrate_forces(s):
	var lv = s.get_linear_velocity()
	var new_anim = anim

	if state == State.DYING:
		new_anim = "die"
	elif state == State.IMMUNE:
		new_anim = "immune"
	elif state == State.WALKING:
		new_anim = "walk"

		var wall_side = 0.0

		for i in range(s.get_contact_count()):
			var cc = s.get_contact_collider_object(i)
			var dp = s.get_contact_local_normal(i)

			if cc:
				if cc is Bullet and not cc.disabled:
					# enqueue call
					call_deferred("_bullet_collider", cc, s, dp)
					break

			if dp.x > 0.9:
				wall_side = 1.0
			elif dp.x < -0.9:
				wall_side = -1.0

		if wall_side != 0 and wall_side != direction:
			direction = -direction
			#($Sprite as Sprite).scale.x = -direction
			($Sprite as Sprite).scale.x *= -1
		if direction < 0 and not rc_left.is_colliding() and rc_right.is_colliding():
			direction = -direction
			#($Sprite as Sprite).scale.x = -direction
			($Sprite as Sprite).scale.x *= -1
		elif direction > 0 and not rc_right.is_colliding() and rc_left.is_colliding():
			direction = -direction
			#($Sprite as Sprite).scale.x = -direction
			($Sprite as Sprite).scale.x *= -1

		lv.x = direction * WALK_SPEED

	if anim != new_anim:
		anim = new_anim
		($AnimationPlayer as AnimationPlayer).play(anim)

	s.set_linear_velocity(lv)


func _die():
	queue_free()


func _pre_explode():
	#make sure nothing collides against this
	$Shape1.queue_free()
	$Shape2.queue_free()
	$Shape3.queue_free()

	# Stay there
	self.rotation = 0
	mode = MODE_STATIC
	($SoundExplode as AudioStreamPlayer2D).play()


func _bullet_collider(cc, s, dp):
	mode = MODE_RIGID
	
	if will_die:
		state = State.DYING
		emit_signal('is_dead')
	else:
		state = State.IMMUNE
	

	s.set_angular_velocity(sign(dp.x) * 33.0)
	physics_material_override.friction = 1
	cc.disable()
	($SoundHit as AudioStreamPlayer2D).play()
