extends Area2D

class PossumPunch extends Reference:
	var name = "Possum Punch"
	var damage = 13
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
	var raw_force_magnitude = 8 * 1000
	var var_force_magnitude = 30 * 1000
	var point
	
	func _init(point, controller_no):
		self.point = point
		self.controller_no = controller_no
		
class PossumKick extends Reference:
	var name = "Possum Kick"
	var damage = 27
	var is_shieldable = true
	var is_destroyable = false
	
	var controller_no
	var is_DI = true
	func get_DI():
		var x_axis = Input.get_joy_axis(controller_no, 0)
		var y_axis = Input.get_joy_axis(controller_no, 1)
		var result = Vector2()
		if abs(x_axis) > 0.5 or abs(y_axis) > 0.5:
			result.x = x_axis
			result.y = y_axis
			result.normalized()
			#print("direction influence over threshold: ", result)
		else:
			#print("direction influence not over threshold")
			pass
		return result
	
	var stun = 1.0
	var raw_force_magnitude = 12 * 1000
	var var_force_magnitude = 40 * 1000
	var point
	
	func _init(point, controller_no):
		self.point = point
		self.controller_no = controller_no
	
func set_possum_kick():
	attack = PossumKick.new(get_node("pos"), get_parent().get_parent().controller_no)

func set_possum_punch():
	attack = PossumPunch.new(get_node("pos"), get_parent().get_parent().controller_no)
var attack
	
func get_attack():
	return attack
	
var is_active = false
func is_attack():
	return is_active


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass
