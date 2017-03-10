extends Control

const TIME_OPEN = 1.5
var cur_time = 0


func _ready():
	get_node("/root/scene_switcher").melee_map_select_music_pos = 0
	set_process(true)
	

func _process(delta):
	if get_node("anim").is_playing():
		return
		
	for i in range(get_node("/root/player_variables").MAX_NUM_PLAYERS):
		if Input.is_joy_button_pressed(i, JOY_SELECT):
			get_node("anim").play("roll_credits")
			return
		
		if Input.is_joy_button_pressed(i, JOY_XBOX_A):
			get_node("/root/scene_switcher").goto_scene("res://melee.tscn")
		
		if Input.is_joy_button_pressed(i, JOY_XBOX_B):
			cur_time = TIME_OPEN
			get_node("controller").show()
		
		if cur_time == 0:
			get_node("controller").hide()
		else:
			cur_time = max (0, cur_time - delta)
		

		
	
