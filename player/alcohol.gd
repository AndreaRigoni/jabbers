class_name Alcohol
extends RigidBody2D

var disabled = true

func _process(delta):
	if not disabled:
		_particle_collision()

func disable():
	disabled = true

func set_particle_collision(x,y,w,h):
	var rect = Rect2(x,y,w,h)
	($ParticleCollision.shape as RectangleShape2D).set_extents(rect.size)
	$ParticleCollision.position = rect.position

func _particle_collision():
	var rect = $Spray.capture_rect()
	($ParticleCollision.shape as RectangleShape2D).set_extents(rect.size/2)
	$ParticleCollision.position = rect.position + rect.size/2

