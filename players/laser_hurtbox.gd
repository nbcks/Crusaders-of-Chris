extends Area2D

class LaserAttack extends Reference:
	var name = "Possum Laser"
	var damage = 5
	var is_shieldable = true
	var is_destroyable = true
	var is_DI = false
	var parent = null
	var stun = 1
	var raw_force_magnitude = 0
	var var_force_magnitude = 1000
	var point
	
	func destroy():
		parent.queue_free()
		
	func _init(parent, point):
		self.parent = parent
		self.point = point
	
var attack
	
func get_attack():
	return attack
	
func is_attack():
	return true


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	attack = LaserAttack.new(get_parent(), get_node("pos"))
