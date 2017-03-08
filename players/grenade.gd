extends RigidBody2D

const TOTAL_TIME = 4.0
var max_time = 0.0
var timer = 0.0

var velocity = Vector2()

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	timer = 0.0
	
func set_time(scle):
	max_time = TOTAL_TIME * scle
	
func activate():
	set_fixed_process(true)
	
func _fixed_process(delta):
	var self_destruct = timer >= max_time

	if self_destruct:
		explode()
		set_fixed_process(false)
	else:
		timer += delta

func explode():
	get_node("area").set_active()
	#get_node("anim").call_deferred("play", "explosion")
	get_node("anim").play("explosion")
	
func destroy():
	queue_free()
