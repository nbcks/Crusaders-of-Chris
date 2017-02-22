extends RigidBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var centre_point
var side_point

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	side_point = get_node("centre")
	centre_point = get_parent().get_node("point")
	
	
	set_fixed_process(true)
	
func _fixed_process(delta):
	var cpos = centre_point.get_global_pos()
	var spos = side_point.get_global_pos()
	print("centre point pos: ", cpos, "side_point pos: ", spos)
	var direction = (cpos - spos).normalized()
	print("directin: ", direction)
	apply_impulse(Vector2(), direction * 1000.0)
