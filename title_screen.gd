extends Control

func _ready():
	set_process(true)
	
func _process(delta):
	for i in range(get_node("/root/player_variables").MAX_NUM_PLAYERS):
		if Input.is_joy_button_pressed(i, JOY_XBOX_A):
			get_node("/root/scene_switcher").goto_scene("res://melee.tscn")
	

		
	
