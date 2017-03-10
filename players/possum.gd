
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
const STOP_FORCE = 1500
const FRICTION = 75
const LOW_FRICTION = 25
const STOPPING_BOUND = 100
const WALK_FORCE = 1000
const WALK_MIN_SPEED = 10
const WALK_MAX_SPEED = 400

var friction = 0

# jumping 
const LOW_JUMP_FRAMES = 5
const MED_JUMP_FRAMES = 10
const HIGH_JUMP_FRAMES = 25

const LOW_JUMP_FORCE = 18 * 1000
const MED_JUMP_FORCE = 22 * 1000
const HIGH_JUMP_FORCE = 24 * 1000

const AIRBOURNE_SIDE_FORCE = 500
const AIRBOURNE_MAX_SPEED = 150
const AIRBOURNE_THRESHOLD = 100

var jump_count = 0 # for double jumps
const JUMP_MAX_AIRBORNE_TIME = 0.2
const MAX_JUMPS = 2

const SLIDE_STOP_VELOCITY = 1.0 # One pixel per second
const SLIDE_STOP_MIN_TRAVEL = 1.0 # One pixel

const VIBERATE_WEAK = 50.0
const VIBERATE_STRONG = 100.0

# physics stuff

var velocity = Vector2()
func set_velocity(velo):
	velocity = velo
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

signal lives_set(lives, player_no)

func set_lives(no):
	lives = no
	emit_signal("lives_set", lives, player_no)

var lives = 0


# control values - these keep track of what buttons are
# actually pressed

# the ctrl queue, a array in a circle which tracks the 
# last key presses for 10 000 frames. Each element
# stores a dictionary of ctrl_string to boolean.
var ctrl_queue = preload("res://misc/CircularQueue.gd").new()

# other

var player_no = null
var controller_no = null
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
const MAX_SHIELD_SCALE = 0.8
const SHIELD_REGEN = 0.7
const SHIELD_DEGEN = 0.8
const SHIELD_STUN = 2.0

var shield_elapsed_time = 0
var cur_shield_scale = 1


func state_name(state):
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
		
# attacks

const PUNCH = 0
const SHOOT = 1
const KICK = 2

const MELEE_TIME = 0.4
const SHOOT_TIME = 0.6
const KICK_TIME = 0.4
var time_attacking = 0
var max_time_attacking = 0

var attack_type = 0

var global_on_floor = false
var apply_friction = false

signal state_change(state, playno)
var cur_state = IDLE

func set_state(state):
	cur_state = state
	emit_signal("state_change", state, player_no)

func set_player_no(player_no):
	self.player_no = player_no
	self.controller_no = player_no - 1
	
const MIN_JOY = 0.4
func update_ctrls():
	
	# set current key presses
	var right = Input.get_joy_axis(controller_no, 0) >= MIN_JOY
	var left = Input.get_joy_axis(controller_no, 0) <= -MIN_JOY
	var jump = Input.is_joy_button_pressed(controller_no, JOY_XBOX_Y)
	var shoot = Input.is_joy_button_pressed(controller_no, JOY_XBOX_X)
	var shield = Input.is_joy_button_pressed(controller_no, JOY_R2)
	var melee = Input.is_joy_button_pressed(controller_no, JOY_XBOX_A)
	var special = Input.is_joy_button_pressed(controller_no, JOY_XBOX_X)
	
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
		if not (area in get_node("hurtboxes").get_children() or area == get_node("hitbox")) and area.has_method("is_attack"):
			if area.is_attack():
				cur_attack_area = area
				return true
			
	return false
	

# the main loop
func _fixed_process(delta):
	# we want update ctrls to run every frame
	# regardless of current state
	update_ctrls()
	
	force.x = 0
	force.y = GRAVITY
	
	get_node("hurtboxes/punch").is_active = false
	
	if cur_state == AIRBOURNE:
		update_state_airbourne(delta)
	elif cur_state == ATTACKING:
		update_state_attacking(delta)
	elif cur_state == WALKING:
		update_state_walking(delta)
	elif cur_state == IDLE:
		update_state_idle(delta)
	elif cur_state == STUNNED: # consider removal
		update_state_stunned(delta)
	elif cur_state == STOPPING:
		update_state_stopping(delta)
	elif cur_state == TAKE:
		update_state_take(delta)
	elif cur_state == SHIELD:
		update_state_shield(delta)
	else:
		print("erroneous state")
		breakpoint

# major helper functions
	
func special_attack():
	time_since_last_shoot = 0
	var laser = preload("res://players/laser.tscn").instance()
	laser.add_collision_exception_with(self)
	var shoot_pos
	if facing_left:
		shoot_pos = get_node("shoot_pos").get_pos()
	else:
		shoot_pos = get_node("shoot_pos").get_pos() * Vector2(-1, 0)
	var pos = get_pos() + shoot_pos
	laser.set_pos(pos)
	get_parent().get_parent().add_child(laser)
	var laser_force = Vector2()
	if facing_left:
		laser_force.x = -1000
	else:
		laser_force.x = 1000
	laser.activate(Vector2(laser_force.x, 0))
	attack_type = SHOOT
	
func melee_attack():
	time_since_last_melee = 0
	if facing_left:
		update_anim_if_not("left_punch")
	else:
		update_anim_if_not("right_punch")
	attack_type = PUNCH
		
func aerial_melee_attack():
	time_since_last_melee = 0
	if facing_left:
		update_anim_if_not("left_air_attack")
	else:
		update_anim_if_not("right_air_attack")
	attack_type = KICK
# dealing jumping
# return true if there is a jump that succeeds, false
# otherwise 
func jump():
	# deal with jumping
	var jumps = ctrl_queue.how_long_pressed_from("jump", 1)
	var jump_release = not ctrl_queue.get_last_ctrl(0)["jump"] and ctrl_queue.get_last_ctrl(1)["jump"]

	
	if (jump_release and jump_count < MAX_JUMPS):
		jumping = true
		jump_count += 1
		
		# so that if you're in the air, it's like jumping
		# off a platform
		velocity.y = 0
	
		if jumps <= LOW_JUMP_FRAMES:
			print("jump low frames")
			force.y -= LOW_JUMP_FORCE
		elif jumps <= MED_JUMP_FRAMES:
			print("jump med frames")
			force.y -= MED_JUMP_FORCE
		elif jumps <= HIGH_JUMP_FRAMES or jumps > HIGH_JUMP_FRAMES:
			force.y -= HIGH_JUMP_FORCE
			print("jump high frames")
		else:
			print ("serious bug")
		return true
	else:
		return false

# returns -1 for no movement, 0 for right
# and 1 for left
func move_sideways(move_force, max_move_speed):
	# deal with moving
	var right = ctrl_queue.get_last_ctrl(0)["right"]
	var left = ctrl_queue.get_last_ctrl(0)["left"]
	var walking
	
	if (right):
		walking = 0
		if velocity.x < max_move_speed:
			facing_left = false
			force.x += move_force
	elif (left):
		walking = 1
		if velocity.x > - max_move_speed:
			facing_left = true
			force.x -= move_force
	else:
		walking = -1
		
	return walking
	
# returns true if on floor
func apply_force(delta):
	if global_on_floor and friction > 0:
		if (velocity.x >= -STOPPING_BOUND and velocity.x <= STOPPING_BOUND):
			velocity.x = 0
		else:	
			var vsign = sign(velocity.x)
			force.x = -vsign * friction # force needs to go opposite
			update_anim_if_not("stopping")
		
	velocity += force * delta
	var motion = velocity * delta
	motion = move(motion)
	
	var on_floor
	if is_colliding():
		# n is the direction of the collision
		var n = get_collision_normal()
		# check if we are on the floor
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
				# If angle to the "up" vectors is < angle tolerance
				# char is on floor
				on_air_time = 0
				jump_count = 0
				on_floor = true
		else: # we're not on the floor 
			on_air_time += delta
			on_floor = false
			
		motion = n.slide(motion)
		velocity = n.slide(velocity)
	else: # we're also not on the floor
		on_air_time += delta
		on_floor = false
		
	move(motion)
	
	global_on_floor = on_floor
	
	return on_floor
				
# FINITE STATE MACHINE METHODS

var time_since_last_shoot = 0
var time_since_last_melee = 0
func update_state_idle(delta):
	var shielding = ctrl_queue.get_last_ctrl(0)["shield"]
	var done_action = false
	
	# first check for attacks
	var under_attack
	if under_attack():
		done_action = true
		under_attack = true
	else:
		under_attack = false
		
	if shielding and not done_action:
		set_state(SHIELD)
		done_action = true
	else:
		shield_elapsed_time = max (0, shield_elapsed_time - delta * SHIELD_REGEN)
		
	var special = ctrl_queue.get_last_ctrl(0)["special"]
	
	if special and not done_action:
		special_attack()
		set_state(ATTACKING)
		done_action = true
	else:
		time_since_last_shoot += delta
		
	var melee = ctrl_queue.get_last_ctrl(0)["melee"]
	
	if melee and not done_action:
		done_action = true
		melee_attack()
		set_state(ATTACKING)
	else:
		time_since_last_melee += delta
	
	var jumping
	if not done_action:
		jumping = jump()
	else:
		jumping = false
	
	var walking
	if not done_action:
		walking = move_sideways(WALK_FORCE, WALK_MAX_SPEED)
	else:
		walking = -1
		
	if jumping: # assume we won't hit anything on the jump
		update_anim_if_not("jump")
		set_state(AIRBOURNE)
	elif walking >= 0:
		if walking == 0:
			update_anim_if_not("walk_right")
		elif walking == 1:
			update_anim_if_not("walk_left")
		else:
			print("SOMETHING SERIOUS FUCKED UP")
			breakpoint
		set_state(WALKING)
	elif not done_action:
		update_anim_if_not("idle")
	
	friction = FRICTION
	var on_floor = apply_force(delta)
	if under_attack:
		set_state(TAKE)
	elif not on_floor:
		set_state(AIRBOURNE)
	
func update_state_airbourne(delta):
	var done_action = false
	
	var under_attack
	if under_attack():
		under_attack = true
		done_action = true
	else:
		under_attack = false
	
	var melee = ctrl_queue.get_last_ctrl(0)["melee"]
	#if melee and time_since_last_melee > 0.5 and not done_action:
	if melee:
		done_action = true
		aerial_melee_attack()
		set_state(ATTACKING) 
		done_action = true
	
	var jumping
	if not done_action:
		jumping = jump()
	else:
		jumping = false

	# deal with side to side movement
	# ignore collision sliding for now
	var old_side = facing_left
	var moving
	if not done_action:
		moving = move_sideways(AIRBOURNE_SIDE_FORCE, AIRBOURNE_MAX_SPEED)
	else:
		moving = -1
	facing_left = old_side # messy solution to keep facing the same way in the air
	
	friction = 0
	var on_floor = apply_force(delta)
	
	if under_attack:
		set_state(TAKE)
	elif on_floor:
		set_state(IDLE)
	
func update_state_attacking(delta):
	# whether we exit attacking mode
	var leave_state = false
	# set hitboxes to active
	if attack_type == PUNCH or attack_type == KICK:
		get_node("hurtboxes/punch").is_active = true
	
	var under_attack 
	if under_attack():
		if cur_attack_area.get_attack().stun > 0:
			under_attack = true
		else:
			under_attack = false
	else:
		under_attack = false
	if not under_attack:
		var hurt_box = get_node("hurtboxes/punch")
		if max_time_attacking <= 0:
			if attack_type == PUNCH:
				hurt_box.set_possum_punch()
				max_time_attacking = MELEE_TIME
				time_attacking = delta
			elif attack_type == SHOOT:
				max_time_attacking = SHOOT_TIME
				time_attacking = delta
			elif attack_type == KICK:
				print("setting hurtbox to kick")
				hurt_box.set_possum_kick()
				max_time_attacking = KICK_TIME
				time_attacking = delta
			else:
				print("something horrific")
				breakpoint
		else:
			time_attacking += delta
			if time_attacking >= max_time_attacking:
				time_attacking = 0
				max_time_attacking = 0
				leave_state = true
		
	var on_floor = apply_force(delta)
	if under_attack:
		set_state(TAKE)
	elif leave_state:
		if on_floor:
			set_state(IDLE)
		else:
			set_state(AIRBOURNE)
			
func update_state_walking(delta):
	
	var shielding = ctrl_queue.get_last_ctrl(0)["shield"]
	var done_action = false
	
	# first check for attacks
	var under_attack
	if under_attack():
		set_state(TAKE)
		done_action = true
		under_attack = true
	else:
		under_attack = false
		
	if shielding and not done_action:
		set_state(SHIELD)
		done_action = true
	else:
		shield_elapsed_time = max (0, shield_elapsed_time - delta * SHIELD_REGEN)
		
	var special = ctrl_queue.get_last_ctrl(0)["special"]
	
	var attacking = false
	if special and not done_action:
		velocity.x = 0
		special_attack()
		done_action = true
		attacking = true
	else:
		time_since_last_shoot += delta
		
	var melee = ctrl_queue.get_last_ctrl(0)["melee"]
	
	if melee and not done_action:
		velocity.x = 0
		done_action = true
		melee_attack()
		attacking = true
	else:
		time_since_last_melee += delta
	
	var jumping
	if not done_action:
		jumping = jump()
	else:
		jumping = false
	
	var walking
	if not done_action:
		walking = move_sideways(WALK_FORCE, WALK_MAX_SPEED)
	else:
		walking = -1
		
	if jumping: # assume we won't hit anything on the jump
		update_anim_if_not("jump")
		set_state(AIRBOURNE)
	elif walking >= 0:
		if walking == 0:
			update_anim_if_not("walk_right")
		elif walking == 1:
			update_anim_if_not("walk_left")
	elif attacking:
		print("walking -> attacking")
		set_state(ATTACKING)
	elif not done_action:
		update_anim_if_not("stopping")
		set_state(STOPPING)
	
	friction = 0
	var on_floor = apply_force(delta)
	
	if not on_floor and not done_action:
		set_state(AIRBOURNE)
	
func update_state_stopping(delta):
	# ignore player side input for now
	# we'll also not be able to jump from the stop state
	
	# we've stopped completely
	if (velocity.x >= -STOPPING_BOUND and velocity.x <= STOPPING_BOUND):
		velocity.x = 0
		set_state(IDLE)
	else:	
		var vsign = sign(velocity.x)
		force.x = -vsign * STOP_FORCE # force needs to go opposite
		update_anim_if_not("stopping")
	
	# friction already implemented here
	friction = 0
	var on_floor = apply_force(delta)
	
	if not on_floor:
		set_state(AIRBOURNE)
	
var time_taken = 0
var max_time_taken = 0
func update_state_take(delta):
	if max_time_taken <= 0:
		apply_friction = true
		Input.start_joy_vibration(controller_no, 0.0, 0.7, 0.7)
		print("applying attack in take")
		# get the current attack and apply the force
		var attack = cur_attack_area.get_attack()
		var name = attack.name
		print("attacked by: ", name)
		print("attack has damage: ", attack.damage)
			
		# how long we remain stunned
		max_time_taken = attack.stun
		time_taken = delta
		
		# apply force in the correct direction: A to B is B - A
		var centre = get_node("centre").get_global_pos()
		var attack_point = attack.point.get_global_pos()
		var direction = (centre - attack_point).normalized()
		if attack.is_DI:
			print("attack has DI")
			var DI = attack.get_DI()
			direction = (direction + DI).normalized()
		else:
			print("attack has no DI")
		print("direction of attack ", direction)
		force += direction * (attack.var_force_magnitude * (health_pc / 100.0) + attack.raw_force_magnitude) 
		print("force applied by attack", force)
		
		# apply damage
		print("player ", player_no, " taking ", attack.damage, " damage")
		set_health(health_pc + attack.damage)
		
		friction = FRICTION
		var on_floor = apply_force(delta)
		
		if attack.is_destroyable:
			print("destroying attack")
			attack.destroy()
		
	else: # so we're just remaining stunned
		time_taken += delta
		if time_taken >= max_time_taken:
			# reset time taken
			max_time_taken = 0
			time_taken = 0
			apply_friction = false
			set_state(IDLE)
			
		force.x = 0
		force.y = GRAVITY
			
		apply_force(delta)
			
	
func update_state_shield(delta):
	get_node("shield").show()
	
	var under_attack
	if under_attack():
		var attack = cur_attack_area.get_attack()
		under_attack = not attack.is_shieldable
	else:
		under_attack = false
		
	shield_elapsed_time += delta
	var shield_pressed = ctrl_queue.get_last_ctrl(0)["shield"]
	
	if under_attack:
		get_node("shield").hide()
		set_state(TAKE)
		return
	
	if shield_elapsed_time > MAX_SHIELD_LENGTH:
		stun_time = SHIELD_STUN
		set_state(STUNNED)
		get_node("shield").hide()
		return
		
	if not shield_pressed:
		set_state(IDLE)
		get_node("shield").hide()
		return
	
	var scle = ((MAX_SHIELD_LENGTH - shield_elapsed_time )/MAX_SHIELD_LENGTH) * MAX_SHIELD_SCALE
	get_node("shield").set_scale(Vector2(scle, scle))
	
# set this variable when state is canged to stunned 
var stun_time = -1

var max_stun_time = 0
var current_stun_time = 0
func update_state_stunned(delta):
	
	var exit_stun = false
	if stun_time != -1:
		max_stun_time = stun_time
		stun_time= -1
		current_stun_time += delta
	else:
		current_stun_time += delta
		if current_stun_time > max_stun_time:
			exit_stun = true
	
	# first check for attacks
	var under_attack
	if under_attack():
		stun_time = -1
		exit_stun = true
		under_attack = true
	else:
		under_attack = false
			
	var on_floor = apply_force(delta)
	
	if exit_stun:
		stun_time = -1
		if under_attack:
			set_state(TAKE)
		elif not on_floor:
			set_state(AIRBOURNE)
		else:
			set_state(IDLE)
	
func update_anim_if_not(track):
	var anim = get_node("anim")
	if anim.get_current_animation() != track or not anim.is_active():
		anim.play(track)

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
