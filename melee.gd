extends Control

const MOUSE_SPEED = 25
const MOUSE_X_MAX = 1920
const MOUSE_X_MIN = 0
const MOUSE_Y_MAX = 1080
const MOUSE_Y_MIN = 0
const MOUSE_MIN_INPUT = 0.4

func activate_players():
	var players = get_node("/root/player_variables").active_players
	for i in range(get_node("/root/player_variables").MAX_NUM_PLAYERS):
		if not players[i] and Input.is_joy_button_pressed(i, JOY_XBOX_A):
			players[i] = true
			print("player %d active!" % (i + 1))

func move_mice():
	var players = get_node("/root/player_variables").active_players
	for i in range(get_node("/root/player_variables").MAX_NUM_PLAYERS):
		if players[i]:
			var x_axis = Input.get_joy_axis(i, 0)
			var y_axis = Input.get_joy_axis(i, 1)
			
			var mouse = get_node("mice").get_child(i)
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
# a character, return the index, else return -1
func pos_in_avatar(pos):
	var i = 0
	var no_characters = get_node("characters").get_child_count()
	var cur_character
	while i < no_characters:
		cur_character = get_node("characters").get_child(i)
		
		var min_x = cur_character.get_node("min_point").get_global_pos().x
		var min_y = cur_character.get_node("min_point").get_global_pos().y
		var max_x = cur_character.get_node("max_point").get_global_pos().x
		var max_y = cur_character.get_node("max_point").get_global_pos().y
		
		if pos.x >= min_x and pos.x <= max_x and pos.y >= min_y and pos.y <= max_y:
			return i
			
		i += 1
		
	return -1
	

func update_selected_chars():
	var players = get_node("/root/player_variables").active_players
	var selected_chars = get_node("/root/player_variables").selected_chars_players
	for i in range(get_node("/root/player_variables").MAX_NUM_PLAYERS):
		if players[i]:
			var mouse = get_node("mice").get_child(i)
			var mouse_pos = mouse.get_node("click").get_global_pos()
			
			var selected_char = pos_in_avatar(mouse_pos)
			
			if selected_char != -1:
				if Input.is_joy_button_pressed(i, JOY_XBOX_A):
					selected_chars[i] = selected_char
			

var players_active = 0
var players_selected = 0
func are_we_ready():
	var players = get_node("/root/player_variables").active_players
	var selected_chars = get_node("/root/player_variables").selected_chars_players
	
	players_active = 0
	players_selected = 0
	for i in range(get_node("/root/player_variables").MAX_NUM_PLAYERS):
		if players[i]:
			players_active += 1
		if selected_chars[i] >= 0:
			players_selected += 1
	var ready = players_active >= 2 and players_selected == players_active
	get_node("ready").set_text("active players: %d\nselected characters: %d\nready: %s" % [players_active, players_selected, ready])
		
	return ready

func _ready():
	get_node("/root/scene_switcher").melee_map_select_music_pos = 0
	set_process(true)
	
func _process(delta):
		
	activate_players()
	
	move_mice()
	
	update_selected_chars()
	
	var ready = are_we_ready()

	if ready:
		get_node("start").show()
		for i in range(8):
			if Input.is_joy_button_pressed(i, JOY_START):
				get_node("/root/scene_switcher").goto_scene("res://map_select.tscn")
	else:
		get_node("start").hide()
		
	
