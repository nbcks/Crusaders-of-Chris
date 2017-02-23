extends Control

func _ready():
	set_process(true)
	
func _process(delta):
	if Input.is_joy_button_pressed(0, JOY_XBOX_A):
		get_node("/root/scene_switcher").goto_scene("res://melee.tscn")
		#get_tree().change_scene("res://melee.tscn")
	

		
	
