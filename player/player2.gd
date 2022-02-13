class_name Player2
extends RigidBody2D

# Character Demo, written by Juan Linietsky.
#
#  Implementation of a 2D Character controller.
#  This implementation uses the physics engine for
#  controlling a character, in a very similar way
#  than a 3D character controller would be implemented.
#
#  Using the physics engine for this has the main advantages:
#    - Easy to write.
#    - Interaction with other physics-based objects is free
#    - Only have to deal with the object linear velocity, not position
#    - All collision/area framework available
#
#  But also has the following disadvantages:
#    - Objects may bounce a little bit sometimes
#    - Going up ramps sends the chracter flying up, small hack is needed.
#    - A ray collider is needed to avoid sliding down on ramps and
#      undesiderd bumps, small steps and rare numerical precision errors.
#      (another alternative may be to turn on friction when the character is not moving).
#    - Friction cant be used, so floor velocity must be considered
#      for moving platforms.

const WALK_ACCEL = 500.0
const WALK_DEACCEL = 500.0
const WALK_MAX_VELOCITY = 140.0
const ILL_WALK_ACCEL = 300.0
const ILL_WALK_DEACCEL = 400.0
const ILL_WALK_MAX_VELOCITY = 80.0

const AIR_ACCEL = 100.0
const AIR_DEACCEL = 100.0
const JUMP_VELOCITY = 380
const ILL_JUMP_VELOCITY = 330
const STOP_JUMP_FORCE = 450.0
const MAX_SHOOT_POSE_TIME = 0.3
const MAX_FLOOR_AIRBORNE_TIME = 0.15

const MAX_JABS=100
const START_JABS = 50

var anim = ""
var siding_left = false
var jumping = false
var stopping_jump = false
var shooting = false
var infected = false
var dying    = false

var floor_h_velocity = 0.0

var airborne_time = 1e20
var shoot_time = 1e20

var Bullet_s = preload("res://player/Bullet.tscn")
var Enemy_s  = preload("res://enemy/Enemy.tscn")

onready var sound_jump = $SoundJump
onready var sound_shoot = $SoundShoot
onready var sprite = $Sprite
onready var sprite_smoke = sprite.get_node(@"Smoke")
onready var animation_player = $AnimationPlayer
onready var bullet_shoot = $BulletShoot
onready var top_ui = $UI/TopBar

onready var collected_coins = 0
onready var dead_patients = 0
onready var jabs = START_JABS

signal coin_collected
signal jab_collected
signal patient_killed
signal shot_bullet
signal infected
signal is_dying

# ready
func _ready():
	top_ui.update()
	var level_timer = get_tree().current_scene.get_node('LevelTimer')
	if level_timer != null: 
		level_timer.connect("timeout", self, "_on_Timer_timeout")
	else:
		print_debug('WARNING: No level timer found')


func _integrate_forces(s):
	var lv = s.get_linear_velocity()
	var step = s.get_step()

	var new_anim = anim
	var new_siding_left = siding_left

	# Get player input.
	var move_left = Input.is_action_pressed("move_left")
	var move_right = Input.is_action_pressed("move_right")
	var jump   = Input.is_action_pressed("jump")
	var shoot  = Input.is_action_pressed("shoot")
	var shoot2 = Input.is_action_pressed("shoot2")
	var spawn  = Input.is_action_pressed("spawn")

	var walk_max_velocity = WALK_MAX_VELOCITY
	var walk_accel = WALK_ACCEL

	if dying:
		move_left = false
		move_right = false
		jump = false
		shoot = false
		spawn = false
		animation_player.play('die')
		return

	if infected:
		walk_max_velocity = ILL_WALK_MAX_VELOCITY
		walk_accel = ILL_WALK_ACCEL
		
	if spawn:
		call_deferred("_spawn_enemy_above")

	# Deapply prev floor velocity.
	lv.x -= floor_h_velocity
	floor_h_velocity = 0.0

	# Find the floor (a contact with upwards facing collision normal).
	var found_floor = false
	var floor_index = -1

	for x in range(s.get_contact_count()):
		var ci = s.get_contact_local_normal(x)

		if ci.dot(Vector2(0, -1)) > 0.6:
			found_floor = true
			floor_index = x

	# A good idea when implementing characters of all kinds,
	# compensates for physics imprecision, as well as human reaction delay.
	if shoot and not shooting:
		call_deferred("shot_bullet")
	elif shoot2 and not shooting:
		call_deferred("_spray_alcohol")
	else:
		shoot_time += step

	if shooting and not (shoot or shoot2):
		call_deferred("_stop_spray_alcohol")

	if found_floor:
		airborne_time = 0.0
	else:
		airborne_time += step # Time it spent in the air.
	var on_floor = airborne_time < MAX_FLOOR_AIRBORNE_TIME

	# Process jump.
	if jumping:
		if lv.y > 0:
			# Set off the jumping flag if going down.
			jumping = false
		elif not jump:
			stopping_jump = true

		if stopping_jump:
			lv.y += STOP_JUMP_FORCE * step

	if on_floor:
		# Process logic when character is on floor.
		if move_left and not move_right:
			if lv.x > - walk_max_velocity:
				lv.x -= walk_accel * step
		elif move_right and not move_left:
			if lv.x < walk_max_velocity:
				lv.x += walk_accel * step
		else:
			var xv = abs(lv.x)
			xv -= WALK_DEACCEL * step
			if xv < 0:
				xv = 0
			lv.x = sign(lv.x) * xv

		# Check jump.
		if not jumping and jump:
			lv.y = -JUMP_VELOCITY
			jumping = true
			stopping_jump = false
			sound_jump.play()

		# Check siding.
		if lv.x < 0 and move_left:
			new_siding_left = true
		elif lv.x > 0 and move_right:
			new_siding_left = false
		if jumping:
			new_anim = "jumping"
		elif abs(lv.x) < 0.1:
			if shoot_time < MAX_SHOOT_POSE_TIME:
				new_anim = "idle_weapon"
			elif infected:
				new_anim = "idle_infected"
			else:
				new_anim = "idle"
		else:
			if shoot_time < MAX_SHOOT_POSE_TIME:
				new_anim = "run_weapon"
			else:
				new_anim = "run"
	else:
		# Process logic when the character is in the air.
		if move_left and not move_right:
			if lv.x > -WALK_MAX_VELOCITY:
				lv.x -= AIR_ACCEL * step
		elif move_right and not move_left:
			if lv.x < WALK_MAX_VELOCITY:
				lv.x += AIR_ACCEL * step
		else:
			var xv = abs(lv.x)
			xv -= AIR_DEACCEL * step

			if xv < 0:
				xv = 0
			lv.x = sign(lv.x) * xv

		if lv.y < 0:
			if shoot_time < MAX_SHOOT_POSE_TIME:
				new_anim = "jumping_weapon"
			else:
				new_anim = "jumping"
		else:
			if shoot_time < MAX_SHOOT_POSE_TIME:
				new_anim = "falling_weapon"
			else:
				new_anim = "falling"

	# Update siding.
	if new_siding_left != siding_left:
		sprite.scale.x *= -1
		if shooting: call_deferred("_adjust_spray_alcohol")
		siding_left = new_siding_left

	# Change animation.
	if new_anim != anim:
		anim = new_anim
		animation_player.play(anim)

	shooting = shoot or shoot2

	# Apply floor velocity.
	if found_floor:
		floor_h_velocity = s.get_contact_collider_velocity_at_position(floor_index).x
		lv.x += floor_h_velocity

	# Finally, apply gravity and set back the linear velocity.
	lv += s.get_total_gravity() * step
	s.set_linear_velocity(lv)


func shot_bullet():
	if jabs > 0:
		_shot_bullet()
		jabs -= 1
		emit_signal("shot_bullet")
		

func _shot_bullet():
	shoot_time = 0
	var bi = Bullet_s.instance()
	var ss
	if siding_left:
		ss = -1.0
	else:
		ss = 1.0
	var pos = position + bullet_shoot.position * Vector2(ss, 1.0)

	bi.position = pos
	bi.get_node("Sprite").scale.x *= ss
	get_parent().add_child(bi)
	
	bi.linear_velocity = Vector2(400.0 * ss, -40)
	sprite_smoke.restart()
	sound_shoot.play()
	add_collision_exception_with(bi) # Make bullet and this not collide.



func _spray_alcohol():
	var ai = $Alcohol
	_adjust_spray_alcohol()
	ai.visible = true
	ai.get_node("Spray").emitting = true
	ai.disabled = false

func _adjust_spray_alcohol():
	var ai = $Alcohol
	var ss = 1
	if siding_left: ss = -1
	ai.position = $AlcoholShoot.position * Vector2(ss,1)
	ai.scale.x  = ss

func _stop_spray_alcohol():
	var ai = $Alcohol
	ai.get_node("Spray").emitting = false
	ai.disabled = true
	ai.visible = false
	ai.set_particle_collision(0,0,0.1,0.1)
	
func _die():
	get_tree().change_scene('res://stills/GameOver.tscn')

func _spawn_enemy_above():
	var e = Enemy_s.instance()
	e.position = position + 50 * Vector2.UP + 100 * Vector2.RIGHT
	get_parent().add_child(e)
	

func set_jab_collected():
	jabs += 20
	emit_signal("jab_collected")

func set_coin_collected():
	collected_coins += 1
	emit_signal("coin_collected")

func set_infected():
	infected = true
	$Explosion.emitting = true
	emit_signal("infected")

func set_cured():
	$Explosion.emitting = false
	infected = false
	
func set_is_dying():
	dying = true
	emit_signal('is_dying')
	



func _on_Timer_timeout():
	print_debug('TIMEOUT !')
	set_is_dying()

func _on_Player2_body_entered(body):
	if body is Enemy:
		set_infected()
	pass

func _on_Patient_is_dead():
	dead_patients += 1
	emit_signal('patient_killed')
	
