extends KinematicBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var velocity = Vector2()

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
func activate(velo):
	velocity = velo
	set_fixed_process(true)
	
func _fixed_process(delta):
	var motion = velocity * delta
	motion = move(motion)
	
	# if hitting a player, that player will destroy it
	var overlap_bodies = get_node("area").get_overlapping_bodies()
	var self_destruct = false
	for body in overlap_bodies:
		if body.has_method("is_player"):
			if not body.is_player():
				self_destruct = true
				print("self destructing ", body.get_name())
				break
		else:
			self_destruct = true
			print("self destructing ", body.get_name())
			break
#	
	if self_destruct:
		queue_free()
#		
			
