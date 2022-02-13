extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var current_scene = get_tree().current_scene
onready var countdown = current_scene.get_node('LevelTimer')

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _process(delta: float) -> void:
	text = _format_seconds(countdown.time_left, false)
	
	
func _format_seconds(time : float, use_milliseconds : bool) -> String:
	var minutes := time / 60
	var seconds := fmod(time, 60)
	if not use_milliseconds:
		return "%02d:%02d" % [minutes, seconds]
	var milliseconds := fmod(time, 1) * 100
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]
