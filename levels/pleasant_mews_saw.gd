extends Node2D

var blade
var base
var arm

var hitbox
var hurtbox

var centre

var cur_attack_area

const ATTACK_REFRESH = 3.5
const SPIN_TIME = 21.0
const IDLE_FORCE  = 1200
const WARNING_TIME = 1.5

var cur_time = 0
var time_since_last_attack = SPIN_TIME - 2.0

func _ready():
	blade = get_node("blade")
	base = get_node("base")
	arm = get_node("arm")
	
	#blade.apply_impulse(Vector2(), Vector2(-1000, 0))
	#blade.set_angular_velocity( 100.0 )
	
	hitbox = get_node("blade/hitbox")
	hurtbox = get_node("blade/hurtbox")
	
	centre = get_node("blade/centre")
	
	set_fixed_process(true)
	
func under_attack():
	var colliding = hitbox.get_overlapping_areas()
	for area in colliding:
		if not (area == hurtbox or area == hitbox) and area.has_method("is_attack"):
			if area.is_attack():
				cur_attack_area = area
				return true
			
	return false

	
func _fixed_process(delta):
	
	if under_attack():
		time_since_last_attack = 0
		if cur_time <= 0:
			cur_time = ATTACK_REFRESH
			
			var attack = cur_attack_area.get_attack()
			
			# apply force in the correct direction: A to B is B - A
			var attack_point = attack.point.get_global_pos()
			var direction = (centre.get_global_pos() - attack_point).normalized()
			
			if attack.is_DI:
				print("attack has DI")
				var DI = attack.get_DI()
				direction = (direction + DI).normalized()
			print("direction of attack ", direction)
			var force = direction * (attack.var_force_magnitude * 0.25 + attack.raw_force_magnitude) * 0.01
			blade.apply_impulse(Vector2(), force)
			print("force applied by attack", force)
			
			if attack.is_destroyable:
				print("destroying attack")
				attack.destroy()
	
	if cur_time > 0:	
		blade.set_angular_velocity(20.0)
		time_since_last_attack = 0
		get_node("warning_sign").hide()
	elif time_since_last_attack >= SPIN_TIME:
		blade.set_angular_velocity(75.0)
		randomize()
		var force = IDLE_FORCE * Vector2(rand_range(-1,1), rand_range(-1, 1)).normalized()
		blade.apply_impulse(Vector2(), Vector2(IDLE_FORCE, -50))
		get_node("warning_sign").hide()
		time_since_last_attack = 0
	elif SPIN_TIME - time_since_last_attack <= WARNING_TIME:
		get_node("warning_sign").show()
	
	
	cur_time = max(0, cur_time - delta)
	time_since_last_attack += delta