extends Reference

var name
var damage 
var is_shieldable = true
var is_destroyable = false

var controller_no
var is_DI = true
func get_DI():
	var x_axis = Input.get_joy_axis(controller_no, 0)
	var y_axis = Input.get_joy_axis(controller_no, 1)
	var result = Vector2()
	if abs(x_axis) > 0.5 or abs(y_axis) > 0.5:
		#print("direction influence over threshold")
		result.x = x_axis
		result.y = y_axis
		result.normalized()
	else:
		#print("direction influence not over threshold")
		pass
	return result

var stun = 0.5
var raw_force_magnitude = 10000
var var_force_magnitude = 100000
var point
