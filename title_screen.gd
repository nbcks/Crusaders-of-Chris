extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var pos_in_menu = -1
var no_menu_items = 0
func _ready():
	set_process(true)
	
func _process(delta):
	if Input.is_action_pressed("player1_melee"):
		get_node("/root/scene_switcher").goto_scene("res://melee.tscn")
		#get_tree().change_scene("res://melee.tscn")
	


# try do it with a controller!
func controller(delta):
	var up = Input.is_action_pressed("player1_right")
	var down = Input.is_action_pressed("player1_left")
	var old_pos_in_menu = pos_in_menu
	
	if (up || down):
		if pos_in_menu == -1:
			old_pos_in_menu = 0
			pos_in_menu = 0
		elif up:
			pos_in_menu = min( no_menu_items - 1, pos_in_menu + 1)
		elif down:
			pos_in_menu = max(0 , pos_in_menu - 1)
		
		get_node("menu").get_child(old_pos_in_menu).set_pressed(false)
		get_node("menu").get_child(pos_in_menu).set_pressed(true)
		
func on_melee_click():
	get_tree().change_scene("res://melee.tscn")
		
		
	
