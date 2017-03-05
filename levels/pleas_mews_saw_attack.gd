extends Area2D

var attack

class SawAttack extends Reference:
	var name = "Saw Attack"
	var damage = 33
	var is_shieldable = false
	var is_destroyable = false
	
	var is_DI = false
	
	var stun = 1.0
	var raw_force_magnitude = 30000
	var var_force_magnitude = 400000
	var point
	
	func _init(point):
		self.point = point

func get_attack():
	return attack
	
func set_active(val):
	is_active = val

var is_active = true
func is_attack():
	return is_active


func _ready():
	attack = SawAttack.new(get_parent().get_node("centre"))
