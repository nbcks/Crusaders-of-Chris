extends Control

func _ready():
	get_node("/root/scene_switcher").melee_map_select_music_pos = 0
	set_process(true)
	
func _process(delta):
	for i in range(get_node("/root/player_variables").MAX_NUM_PLAYERS):
		if Input.is_joy_button_pressed(i, JOY_XBOX_A):
			get_node("/root/scene_switcher").goto_scene("res://melee.tscn")
		
		if Input.is_joy_button_pressed(i, JOY_SELECT):
			get_node("controller").show()
		else:
			get_node("controller").hide()
	

		
	
