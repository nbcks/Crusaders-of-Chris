
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
const WALK_FORCE = 600
const WALK_MIN_SPEED = 10
const WALK_MAX_SPEED = 200
const STOP_FORCE = 1300
const JUMP_SPEED = 200
const JUMP_MAX_AIRBORNE_TIME = 0.2

const SLIDE_STOP_VELOCITY = 1.0 # One pixel per second
const SLIDE_STOP_MIN_TRAVEL = 1.0 # One pixel

var velocity = Vector2()
var on_air_time = 100
var jumping = false

var prev_jump_pressed = false

# health stuff 
# signal should be emitted whenever the health is changed
signal health_set(health)

# this should be used to set the health
func set_health(x):
	health_pc = x
	emit_signal("health_set", x)
	
var health_pc = 0

#control:
#these are strings which refer to the 
#(hopefully) the button for this instance

var jump_ctrl = null
var shoot_ctrl = null
var shield_ctrl = null
var melee_ctrl = null

var left_ctrl = null
var right_ctrl = null

# control values - these keep track of what buttons are
# actually pressed

var jump = false
var old_jump = false

var shoot = false
var old_shoot = false

var shield = false
var old_shield = false

var left = false
var old_left = false

var right = false
var old_right = false

var melee = false
var old_melee = false

# other

var player_no = 0

func set_player_ctrls(player_no):
	jump_ctrl = "player%d_jump" % player_no
	shoot_ctrl = "player%d_shoot" % player_no
	shield_ctrl = "player%d_shield" % player_no
	melee_ctrl = "player%d_melee" % player_no
	
	left_ctrl = "player%d_left" % player_no
	right_ctrl = "player%d_right" % player_no
	
	self.player_no = player_no


func _fixed_process(delta):
	# Create forces
	var force = Vector2(0, GRAVITY)
	
	# set controls
	# set old key presses
	old_right = right
	old_left = left
	
	old_shield = shield
	old_jump = jump
	old_melee = melee
	old_shoot = shoot
	
	# set current key presses
	right = Input.is_action_pressed(right_ctrl)
	left = Input.is_action_pressed(left_ctrl)
	jump = Input.is_action_pressed(jump_ctrl)
	shoot = Input.is_action_pressed(shoot_ctrl)
	shield = Input.is_action_pressed(shield_ctrl)
	melee = Input.is_action_pressed(melee_ctrl)
	
	var stop = true
	
	if (left):
		if (velocity.x <= WALK_MIN_SPEED and velocity.x > -WALK_MAX_SPEED):
			force.x -= WALK_FORCE
			stop = false
	elif (right):
		if (velocity.x >= -WALK_MIN_SPEED and velocity.x < WALK_MAX_SPEED):
			force.x += WALK_FORCE
			stop = false
	
	if (stop):
		var vsign = sign(velocity.x)
		var vlen = abs(velocity.x)
		
		vlen -= STOP_FORCE*delta
		if (vlen < 0):
			vlen = 0
		
		velocity.x = vlen*vsign
	
	# Integrate forces to velocity
	velocity += force*delta
	
	# Integrate velocity into motion and move
	var motion = velocity*delta
	
	# Move and consume motion
	motion = move(motion)
	
	var floor_velocity = Vector2()
	
	if (is_colliding()):
		# You can check which tile was collision against with this
		# print(get_collider_metadata())
		
		# Ran against something, is it the floor? Get normal
		var n = get_collision_normal()
		
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
			# If angle to the "up" vectors is < angle tolerance
			# char is on floor
			on_air_time = 0
			floor_velocity = get_collider_velocity()
		
		if (on_air_time == 0 and force.x == 0 and get_travel().length() < SLIDE_STOP_MIN_TRAVEL and abs(velocity.x) < SLIDE_STOP_VELOCITY and get_collider_velocity() == Vector2()):
			# Since this formula will always slide the character around, 
			# a special case must be considered to to stop it from moving 
			# if standing on an inclined floor. Conditions are:
			# 1) Standing on floor (on_air_time == 0)
			# 2) Did not move more than one pixel (get_travel().length() < SLIDE_STOP_MIN_TRAVEL)
			# 3) Not moving horizontally (abs(velocity.x) < SLIDE_STOP_VELOCITY)
			# 4) Collider is not moving
			
			revert_motion()
			velocity.y = 0.0
		else:
			# For every other case of motion, our motion was interrupted.
			# Try to complete the motion by "sliding" by the normal
			motion = n.slide(motion)
			velocity = n.slide(velocity)
			# Then move again
			move(motion)
	
	if (floor_velocity != Vector2()):
		# If floor moves, move with floor
		move(floor_velocity*delta)
	
	if (jumping and velocity.y > 0):
		# If falling, no longer jumping
		jumping = false
	
	# on_air_time < JUMP_MAX_AIRBORNE_TIME
	if (on_air_time == 0 and jump and not prev_jump_pressed and not jumping):
		# Jump must also be allowed to happen if the character left the floor a little bit ago.
		# Makes controls more snappy.
		velocity.y = -JUMP_SPEED
		jumping = true
	
	on_air_time += delta
	prev_jump_pressed = jump


func print_boxes():
	print("player ", player_no, " hitbox: ", get_node("hitbox"), " hurtbox: ", get_node("hurtboxes/punch"))
	
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
	
func _ready():
	get_node("hitbox").connect("area_enter", self, "_on_hit")
	set_fixed_process(true)
