extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	
	set_process(true)
	
const MOUSE_SPEED = 25
const MOUSE_X_MAX = 1920
const MOUSE_X_MIN = 0
const MOUSE_Y_MAX = 1080
const MOUSE_Y_MIN = 0
const MOUSE_MIN_INPUT = 0.4
	

func move_mice():
	var players = get_node("/root/player_variables").active_players
	players[0] = true # DEBUG
	for i in range(8):
		if players[i]:
			var x_axis = Input.get_joy_axis(i, 0)
			var y_axis = Input.get_joy_axis(i, 1)
			
			var mouse = get_node("cursor")
			var mouse_pos = mouse.get_global_pos()
			#print("mouse pos: ", mouse_pos)
			
			if abs(x_axis) < MOUSE_MIN_INPUT:
				#print("mouse input not enough")
				x_axis = 0
			if abs(y_axis) < MOUSE_MIN_INPUT:
				#print("mouse input not enough")
				y_axis = 0
			
			if mouse_pos.y <= MOUSE_Y_MIN:
				y_axis = max (y_axis, 0)
				#print("y too small")
			elif mouse_pos.y >= MOUSE_Y_MAX:
				y_axis = min (y_axis, 0)
				#print("y too big")
			elif mouse_pos.x <= MOUSE_X_MIN:
				x_axis = max (x_axis, 0)
				#print("x too small")
			elif mouse_pos.x >= MOUSE_X_MAX:
				x_axis = min (x_axis, 0)
				#print("x too big")
			
			mouse.set_global_pos( mouse_pos + Vector2(x_axis * MOUSE_SPEED, y_axis * MOUSE_SPEED) )

	
func _process(delta):
	
	move_mice()
