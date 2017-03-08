extends Area2D

class GrenadeAttack extends Reference:
	var name = "Grenade attack"
	var damage = 15
	var is_shieldable = false
	var is_destroyable = false
	var is_DI = false
	var parent = null
	var stun = 1
	var raw_force_magnitude = 7 * 1000
	var var_force_magnitude = 37 * 1000
	var point
	
	func destroy():
		parent.queue_free()
		
	func _init(parent, point):
		self.parent = parent
		self.point = point
	
var attack
	
func get_attack():
	return attack

func set_active():
	is_active = true

var is_active = false
func is_attack():
	return is_active


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	attack = GrenadeAttack.new(get_parent(), get_node("pos"))
