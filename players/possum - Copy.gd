
extends KinematicBody2D

# This is a simple collision demo showing how
# the kinematic controller works.
# move() will allow to move the node, and will
# always move it to a non-colliding spot,
# as long as it starts from a non-colliding spot too.

# Member variables
const GRAVITY = 500.0 # Pixels/second

# Angle in degrees towards either side that the player can consider "floor"
const FLOOR_ANGLE_TOLERANCE = 40

# walking
const STOP_FORCE = 200
const STOPPING_BOUND = 100
const WALK_FORCE = 300
const WALK_MIN_SPEED = 10
const WALK_MAX_SPEED = 150

# jumping 
const LOW_JUMP_FRAMES = 5
const MED_JUMP_FRAMES = 15
const HIGH_JUMP_FRAMES = 30

const LOW_JUMP_FORCE = 16000
const MED_JUMP_FORCE = 32000
const HIGH_JUMP_FORCE = 48000

const AIRBOURNE_SIDE_FORCE = 100
const AIRBOURNE_THRESHOLD = 100

var jump_count = 0 # for double jumps
const JUMP_MAX_AIRBORNE_TIME = 0.2
const MAX_JUMPS = 2

const SLIDE_STOP_VELOCITY = 1.0 # One pixel per second
const SLIDE_STOP_MIN_TRAVEL = 1.0 # One pixel

# physics stuff

var velocity = Vector2()
var on_air_time = 100
var jumping = false
var jump_no = 0 # to allow for double jumping or more
var force = Vector2()
var facing_left = true

var prev_jump_pressed = false

# health stuff 
# signal should be emitted whenever the health is changed 
signal health_set(health, number) 

# this should be used to set the health
func set_health(x):
	health_pc = x
	emit_signal("health_set", x, player_no)
	
var health_pc = 0

#control:
#these are strings which refer to the 
#(hopefully) the button for this instance

var jump_ctrl = null
var shoot_ctrl = null
var shield_ctrl = null
var melee_ctrl = null
var special_ctrl = null

var left_ctrl = null
var right_ctrl = null

# control values - these keep track of what buttons are
# actually pressed

# the ctrl queue, a array in a circle which tracks the 
# last key presses for 10 000 frames. Each element
# stores a dictionary of ctrl_string to boolean.
var ctrl_queue = preload("res://misc/CircularQueue.gd").new()

# other

var player_no = null
var cur_attack_area = null

# states we'll run a unique function depending on the state. 

const AIRBOURNE = 0
const ATTACKING = 1
const WALKING = 2
const IDLE = 3
const STUNNED = 4
const STOPPING = 5
const TAKE = 6
const SHIELD = 7

const MAX_SHIELD_LENGTH = 2
const MAX_SHIELD_SCALE = 0.1
const SHIELD_REGEN = 0.7
const SHIELD_DEGEN = 0.8
var shield_elapsed_time = 0
var cur_shield_scale = 1


static func state_name(state):
	if state == AIRBOURNE:
		return "airbourne"
	elif state == ATTACKING:
		return "attacking"
	elif state == WALKING:
		return "walking"
	elif state == IDLE:
		return "idle"
	elif state == STUNNED:
		return "stunned"
	elif state == STOPPING:
		return "stopping"
	elif state == TAKE:
		return "take"
	elif state == SHIELD:
		return "shield"
	else:
		return "non-existant state"

signal state_change(state, playno)
var cur_state = IDLE

func set_state(state):
	cur_state = state
	emit_signal("state_change", state, player_no)

func set_player_no(player_no):
	jump_ctrl = "player%d_jump" % player_no
	shoot_ctrl = "player%d_shoot" % player_no
	shield_ctrl = "player%d_shield" % player_no
	melee_ctrl = "player%d_melee" % player_no
	special_ctrl = "player%d_special" % player_no
	
	left_ctrl = "player%d_left" % player_no
	right_ctrl = "player%d_right" % player_no
	
	self.player_no = player_no
	
func update_ctrls():
	
	# set current key presses
	var right = Input.is_action_pressed(right_ctrl)
	var left = Input.is_action_pressed(left_ctrl)
	var jump = Input.is_action_pressed(jump_ctrl)
	var shoot = Input.is_action_pressed(shoot_ctrl)
	var shield = Input.is_action_pressed(shield_ctrl)
	var melee = Input.is_action_pressed(melee_ctrl)
	var special = Input.is_action_pressed(special_ctrl)
	
	# set controls
	# set old key presses
	var press = {
		"jump" : jump,
		"shoot" : shoot,
		"left" : left, 
		"right" : right, 
		"shield" : shield, 
		"melee" : melee,
		"special" : special
	}
	
	ctrl_queue.add_ctrls(press)
	
# if a hurtbox has intersected then report it
func under_attack():
	var colliding = get_node("hitbox").get_overlapping_areas()
	for area in colliding:
		if not (area in get_node("hurtboxes").get_children() or area == get_node("hitbox")) and area.has_method("get_attack"):
			cur_attack_area = area
			return true
	
	return false
	

# the main loop
func _fixed_process(delta):
	# we want update ctrls to run every frame
	# regardless of current state
	update_ctrls()
	
	if cur_state == AIRBOURNE:
		update_state_airbourne(delta)
	elif cur_state == ATTACKING:
		update_state_attacking(delta)
	elif cur_state == WALKING:
		update_state_walking(delta)
	elif cur_state == IDLE:
		update_state_idle(delta)
	elif cur_state == STUNNED: # consider removal
		# player can't do anything
		pass
	elif cur_state == STOPPING:
		update_state_stopping(delta)
	elif cur_state == TAKE:
		update_state_take(delta)
	elif cur_state == SHIELD:
		update_state_shield(delta)
	else:
		print("erroneous state")
		breakpoint
	
# FINITE STATE MACHINE METHODS

var time_since_last_shoot = 0
var time_since_last_melee = 0
func update_state_idle(delta):
	var shielding = ctrl_queue.get_last_ctrl(0)["shield"]
		
	# first check for attacks
	if under_attack():
		set_state(TAKE)
		print("player: ", player_no, " under attack!")
		return
	else:
		pass
		
	if shielding:
		set_state(SHIELD)
		return
	else:
		shield_elapsed_time -= delta * SHIELD_REGEN
	
	var floor_velocity
	var n
	var on_floor = false
	if (is_colliding()):
		# n is the direction of the collision
		n = get_collision_normal()
		# check if we are on the floor
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
				# If angle to the "up" vectors is < angle tolerance
				# char is on floor
				on_air_time = 0
				jump_count = 0
				floor_velocity = get_collider_velocity()
				on_floor = true
		else: # we're not on the floor 
			on_air_time += delta
	else: # we're also not on the floor
		on_air_time += delta
		
	if on_air_time > AIRBOURNE_THRESHOLD:
		set_state(AIRBOURNE)
		return
		
	var special = ctrl_queue.get_last_ctrl(0)["special"]
		
	if special and time_since_last_shoot > 0.7:
		print("special")
		time_since_last_shoot = 0
		var laser = preload("res://players/laser.tscn").instance()
		var pos = get_pos() + get_node("shoot_pos").get_pos()
		laser.set_pos(pos)
		get_parent().get_parent().add_child(laser)
		laser.activate(Vector2(-1000,0))
		set_state(ATTACKING)
		return
	else:
		time_since_last_shoot += delta
		
	var melee = ctrl_queue.get_last_ctrl(0)["melee"]
	
	if melee and time_since_last_melee > 0.5:
		time_since_last_shoot = 0
		if facing_left:
			update_anim_if_not("left_punch")
		else:
			update_anim_if_not("right_punch")
		set_state(ATTACKING)
		return
	else:
		time_since_last_melee += delta
		
		
	
		
	# state transitions
	
	# deal with jumping
	var jumps = ctrl_queue.how_long_pressed_from("jump", 1)
	var jump_release = not ctrl_queue.get_last_ctrl(0)["jump"] and ctrl_queue.get_last_ctrl(1)["jump"]
	var jumping = false
	
	if (jump_release):
		jumping = true
		jump_count += 1
		if jumps <= LOW_JUMP_FRAMES:
			print("jump low frames")
			force.y = -LOW_JUMP_FORCE
		elif jumps <= MED_JUMP_FRAMES:
			print("jump med frames")
			force.y = -MED_JUMP_FORCE
		elif jumps <= HIGH_JUMP_FRAMES or jumps > HIGH_JUMP_FRAMES:
			force.y = -HIGH_JUMP_FORCE
			print("jump high frames")
		else:
			print ("serious bug")
	else:
		force.y = GRAVITY
		
	# deal with moving
	var right = ctrl_queue.get_last_ctrl(0)["right"]
	var left = ctrl_queue.get_last_ctrl(0)["left"]
	var walking = false
	
	if (right):
		facing_left = false
		walking = true
		force.x = WALK_FORCE
	elif (left):
		facing_left = true
		walking = true
		force.x = -WALK_FORCE
	else:
		walking = false
		force.x = 0
		
	if jumping: # assume we won't hit anything on the jump
		velocity += force * delta
		var motion = velocity *  delta
		motion = move(motion)
		update_anim_if_not("jump")
		set_state(AIRBOURNE)
	elif walking:
		velocity += force * delta
		var motion = velocity *  delta
		motion = move(motion)
		# sliding
		if on_floor:
			motion = n.slide(motion)
			velocity = n.slide(velocity)
		move(motion)
		if right:
			update_anim_if_not("walk_right")
		elif left:
			update_anim_if_not("walk_left")
		else:
			print("SOMETHING SERIOUS FUCKED UP")
			breakpoint
		set_state(WALKING)
	else:
		update_anim_if_not("idle")
	
func update_state_airbourne(delta):
	var floor_velocity
	var n
	var on_floor = false
	if (is_colliding()):
		# n is the direction of the collision
		n = get_collision_normal()
		# check if we are on the floor
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
				# If angle to the "up" vectors is < angle tolerance
				# char is on floor
				on_air_time = 0
				jump_count = 0
				on_floor = true
		else: # we're in the air but colliding TODO
			on_air_time += delta
	else:
		on_air_time += delta
		
	if on_air_time <= 0:
		set_state(IDLE)
		return
	
	# CRASH CODE
	#A()
	
	# state transitions
	
	# deal with jumping
	var jumps = ctrl_queue.how_long_pressed_from("jump", 1)
	var jump_release = not ctrl_queue.get_last_ctrl(0)["jump"] and ctrl_queue.get_last_ctrl(1)["jump"]
	var jumping = false
	
	if jump_release and jump_count < MAX_JUMPS:
		jumping = true
		jump_count += 1
		update_anim_if_not("jump")
		if jumps <= LOW_JUMP_FRAMES:
			print("jump low frames")
			force.y = -LOW_JUMP_FORCE
		elif jumps <= MED_JUMP_FRAMES:
			print("jump med frames")
			force.y = -MED_JUMP_FORCE
		elif jumps <= HIGH_JUMP_FRAMES or jumps > HIGH_JUMP_FRAMES:
			force.y = -HIGH_JUMP_FORCE
			print("jump high frames")
		else:
			print ("serious bug")
	else:
		force.y = GRAVITY
		
	# deal with side to side movement
	# ignore collision sliding for now
	
	var right = ctrl_queue.get_last_ctrl(0)["right"]
	var left = ctrl_queue.get_last_ctrl(0)["left"]
		
	if (right):
		force.x = AIRBOURNE_SIDE_FORCE
	elif (left):
		force.x = -AIRBOURNE_SIDE_FORCE
	else:
		force.x = 0
		
	# movement
	velocity += force * delta
	var motion = velocity * delta
	motion = move(motion)
	
const MELEE_TIME = 0.5
const SHOOT_TIME = 0.7
var time_attacking = 0
var max_time_attacking = 0
func update_state_attacking(delta):
	if max_time_attacking <= 0:
		if time_since_last_melee == 0:
			max_time_attacking = MELEE_TIME
			time_attacking = delta
		elif time_since_last_shoot == 0:
			max_time_attacking = SHOOT_TIME
			time_attacking = delta
		else:
			print("something horrific")
			breakpoint
	else:
		time_attacking += delta
		if time_attacking >= max_time_attacking:
			time_attacking = 0
			max_time_attacking = 0
			set_state(IDLE)
	
	# do all the normal crap
	force.x = 0
	force.y = GRAVITY
	
	velocity += force * delta
	var motion = velocity *  delta
	motion = move(motion)
			
func update_state_walking(delta):
	#check that we are still on the floor
	var floor_velocity
	var n
	var on_floor = false
	if (is_colliding()):
		# n is the direction of the collision
		n = get_collision_normal()
		# check if we are on the floor
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
				# If angle to the "up" vectors is < angle tolerance
				# char is on floor
				on_air_time = 0
				jump_count = 0
				floor_velocity = get_collider_velocity()
				on_floor = true
		else: # we're not on the floor 
			on_air_time += delta
	else: # we're also not on the floor
		on_air_time += delta
		
	if (on_air_time > AIRBOURNE_THRESHOLD):
		set_state(AIRBOURNE)
		return
		
	# deal with jumping
	var jumps = ctrl_queue.how_long_pressed_from("jump", 1)
	var jump_release = not ctrl_queue.get_last_ctrl(0)["jump"] and ctrl_queue.get_last_ctrl(1)["jump"]
	var jumping = false
	
	if (jump_release):
		jumping = true
		jump_count += 1
		if jumps <= LOW_JUMP_FRAMES:
			print("jump low frames")
			force.y = -LOW_JUMP_FORCE
		elif jumps <= MED_JUMP_FRAMES:
			print("jump med frames")
			force.y = -MED_JUMP_FORCE
		elif jumps <= HIGH_JUMP_FRAMES or jumps > HIGH_JUMP_FRAMES:
			force.y = -HIGH_JUMP_FORCE
			print("jump high frames")
		else:
			print ("serious bug")
	else:
		force.y = GRAVITY
		
	# deal with moving
	var right = ctrl_queue.get_last_ctrl(0)["right"]
	var left = ctrl_queue.get_last_ctrl(0)["left"]
	var walking = false
	
	if (right):
		walking = true
		if velocity.x < WALK_MAX_SPEED:
			force.x = WALK_FORCE
	elif (left):
		walking = true
		if velocity.x > - WALK_MAX_SPEED:
			force.x = -WALK_FORCE
	else:
		walking = false
		force.x = 0
		
	if jumping: # assume we won't hit anything on the jump
		velocity += force * delta
		var motion = velocity *  delta
		motion = move(motion)
		update_anim_if_not("jump")
		set_state(AIRBOURNE)
	elif walking:
		velocity += force * delta
		var motion = velocity *  delta
		motion = move(motion)
		#sliding
		if on_floor:
			motion = n.slide(motion)
			velocity = n.slide(velocity)
		move(motion)
		if right:
			update_anim_if_not("walk_right")
		elif left:
			update_anim_if_not("walk_left")
	else:
		update_anim_if_not("stopping")
		set_state(STOPPING)
	
func update_state_stopping(delta):
	var floor_velocity
	if (is_colliding()):
		# n is the direction of the collision
		var n = get_collision_normal()
		# check if we are on the floor
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
				# If angle to the "up" vectors is < angle tolerance
				# char is on floor
				on_air_time = 0
				jump_count = 0
				floor_velocity = get_collider_velocity()
		else: # we're not on the floor 
			on_air_time += delta
	else: # we're also not on the floor
		on_air_time += delta
	
	if on_air_time > AIRBOURNE_THRESHOLD:
		set_state(AIRBOURNE)
		return
		
	# ignore player side input for now
	# we'll also not be able to jump from the stop state
	
	# we've stopped completely
	if (velocity.x >= -STOPPING_BOUND and velocity.x <= STOPPING_BOUND):
		velocity.x = 0
		set_state(IDLE)
		return
		
	var vsign = sign(velocity.x)
	force.x = -vsign * STOP_FORCE # force needs to go opposite
	update_anim_if_not("stopping")
	
	velocity += force * delta
	var motion = velocity * delta
	motion = move(motion)
	
var time_taken = 0
var max_time_taken = 0
func update_state_take(delta):
	if max_time_taken <= 0:
		print("applying attack in take")
		# get the current attack and apply the force
		var attack = cur_attack_area.get_attack()
			
		# how long we remain stunned
		max_time_taken = attack.stun
		time_taken = delta
		
		# apply force in the correct direction: A to B is B - A
		var direction = (get_node("centre").get_pos() - attack.point.get_pos()).normalized()
		print("direction of attack ", direction)
		print("force_magnitude ", attack.force_magnitude)
		force = direction * attack.force_magnitude
		print("force applied by attack", force)
		
		# apply damage
		print("player ", player_no, " taking ", attack.damage, " damage")
		set_health(health_pc + attack.damage)
		
		print("current velocity: ", velocity)
		force.x = 1000000
		force.y = 0
		
		velocity += force * delta
		var motion = velocity * delta
		motion = move(motion)
		
		if attack.is_destroyable:
			print("destroying attack")
			attack.destroy()
		
	else: # so we're just remaining stunned
		time_taken += delta
		if time_taken >= max_time_taken:
			# reset time taken
			max_time_taken = 0
			time_taken = 0
			set_state(IDLE)
			
			force.x = 0
			force.y = GRAVITY
			
			velocity += force * delta
			var motion = velocity * delta
			motion = move(motion)
			
	
	
	
func update_state_shield(delta):
	get_node("shield").show()
	shield_elapsed_time += delta
	var shield_pressed = ctrl_queue.get_last_ctrl(0)["shield"]
	
	if shield_elapsed_time > MAX_SHIELD_LENGTH:
		set_state(IDLE)
		get_node("shield").hide()
		return
		
	if not shield_pressed:
		set_state(IDLE)
		get_node("shield").hide()
		return
	
	var scle = (MAX_SHIELD_LENGTH - shield_elapsed_time )/MAX_SHIELD_LENGTH
	get_node("shield").set_scale(Vector2(scle, scle))
	
func update_anim_if_not(track):
	var anim = get_node("anim")
	if anim.get_current_animation() != track:
		anim.play(track)

func print_boxes():
	print("player ", player_no, " hitbox: ", get_node("hitbox"), " hurtbox: ", get_node("hurtboxes/punch"))
	
func A():
	var x = B()
	return
func B():
	var b = A()
	return
	
# deal with attacks
func _on_hit(area):
	# we can't get hit by our own hitboxes or hurtboxes!
	if area in get_node("hurtboxes").get_children() or area == get_node("hitbox"):
		return
	var attack = null
	#print("player ", player_no, "has been HIT by: ", area, " hitbox: ", get_node("hitbox"), " hurtbox: ", get_node("hurtboxes/punch"))
	
	if area.has_method("get_attack"):
		attack = area.get_attack()
		set_health(health_pc + attack.damage)
		print("player ", player_no, " health at: ", health_pc)
		
func is_player():
	return true
	
func _ready():
	#get_node("hitbox").connect("area_enter", self, "_on_hit")
	
	var dummy = {
		"jump" : false,
		"shoot" : false,
		"left" : false, 
		"right" : false, 
		"shield" : false, 
		"melee" : false,
		"special" : false
	}
	
	for i in range(ctrl_queue.QUEUE_SIZE):
		ctrl_queue.add_ctrls(dummy)
	
	get_node("shield").set_scale(Vector2(MAX_SHIELD_SCALE, MAX_SHIELD_SCALE))
	
	set_fixed_process(true)
