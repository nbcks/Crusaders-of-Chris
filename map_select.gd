extends Control

var players
var player_vars

func _ready():
	player_vars = get_node("/root/player_variables")
	players = player_vars.players
	
	set_process(true)
	
const MOUSE_SPEED = 25
const MOUSE_X_MAX = 1920
const MOUSE_X_MIN = 0
const MOUSE_Y_MAX = 1080
const MOUSE_Y_MIN = 0
const MOUSE_MIN_INPUT = 0.4

var cur_map_selected = -1

const TESTING = 0
const FINAL_CHRIS = 1

func map_to_path(no):
	if no == TESTING:
		return "res://levels/level1.tscn"
	elif no == FINAL_CHRIS:
		return "res://levels/final_chris.tscn"
	else:
		breakpoint

func move_mice():
	for i in range(get_node("/root/player_variables").MAX_NUM_PLAYERS):
		if players[i]["active"]:
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

# take a global position vector, if it's in 
# a map, return the index, else return -1
func pos_in_avatar(pos):
	var i = 0
	var no_maps = get_node("maps").get_child_count()
	var cur_map
	while i < no_maps:
		cur_map = get_node("maps").get_child(i)
		
		var min_x = cur_map.get_node("min_point").get_global_pos().x
		var min_y = cur_map.get_node("min_point").get_global_pos().y
		var max_x = cur_map.get_node("max_point").get_global_pos().x
		var max_y = cur_map.get_node("max_point").get_global_pos().y
		
		if pos.x >= min_x and pos.x <= max_x and pos.y >= min_y and pos.y <= max_y:
			return i
			
		i += 1
		
	return -1
	
func update_selected_maps():
	
	for i in range(get_node("/root/player_variables").MAX_NUM_PLAYERS):
		if players[i]["active"]:
			var mouse_pos = get_node("cursor").get_node("click").get_global_pos()
			
			var selected_map = pos_in_avatar(mouse_pos)
			
			if selected_map != -1:
				if Input.is_joy_button_pressed(i, JOY_XBOX_A):
					cur_map_selected = selected_map
					
func _process(delta):
	
	move_mice()

	update_selected_maps()
	
	if cur_map_selected != -1:
		get_node("start").show()
		for i in range(player_vars.MAX_NUM_PLAYERS):
			if players[i]["active"]:
				if Input.is_joy_button_pressed(i, JOY_START):
					get_node("/root/scene_switcher").goto_scene(map_to_path(cur_map_selected))
	else:
		get_node("start").hide()