extends Node2D

#all levels must have:
#	1) an instanced melee_ui
#	2) a node2d players with players as children
#	3) a blast_area area2d
#	4) a node 2d spawns with MAX_NUM_PLAYERS Position2D's 

var player_vars
var players
var MAX_NUM_PLAYERS
var no_players = 0

func _ready():
	player_vars = get_node("/root/player_variables")
	
	# DEBUG REMOVE IN PRODUCT
	player_vars.set_possum_2()
	
	players = player_vars.players
	no_players = 0
	MAX_NUM_PLAYERS = get_node("/root/player_variables").MAX_NUM_PLAYERS
	
	var i = 0
	while i < MAX_NUM_PLAYERS:
		if players[i]["active"]:
			var path = player_vars.player_to_path(players[i]["character"])
			var player = ResourceLoader.load(path).instance()
			
			get_node("players").add_child(player)
			player.set_global_pos(get_node("spawns").get_child(i).get_global_pos())
			players[i]["node"] = player
			
			players[i]["active"] = true
			players[i]["alive"] = true
			players[i]["health"] = 0
			players[i]["lives"] = 5
			
			# this needs to happen before, since we want
			# the health and lives set below to update ui
			player.connect("lives_set", self, "player_lives")
			player.connect("health_set", self, "player_health")
			player.connect("state_change", self, "change_state")
			
			# player number index is 1 based rather than 0 based
			var player_no = i + 1
			
			get_node("melee_ui").register_player( player_no, player)
			
			player.set_player_no(player_no)
			player.set_lives(players[i]["lives"])
			player.set_health(players[i]["health"])
			
			no_players += 1
			
		i += 1
			
	get_node("blast_area").connect("body_enter", self, "chuck_to_centre")
	get_node("melee_ui").activate_camera()
	
func chuck_to_centre(body):
	body.set_pos(Vector2(500, 0))
	if body.has_method("set_health"):
		body.set_health(0)
	if body.has_method("set_velocity"):
		body.set_velocity(Vector2())
	if body.has_method("is_player"):
		if body.is_player():
			if body.lives > 1:
				body.set_lives(body.lives - 1)
			else:
				# eliminated player
				print("player: ", body.player_no, " eliminated!")
				
				players[body.player_no - 1]["alive"] = false
				players[body.player_no - 1]["active"] = false
				players[body.player_no - 1]["node"] = null
				
				body.queue_free()
				
				var player_won = player_vars.player_won()
				if player_won != -1:
					turn_off_processing()
					
					victory_screen(player_won)
					
func victory_screen(player_won):
	get_node("melee_ui").set_victory_no(player_won)
	
	
func change_state(state, playerno):
	if get_node("players").get_child_count() > 0:
		print("player ", playerno, " ", get_node("players").get_child(0).state_name(state))
	else:
		breakpoint
	
func player_lives(lives, playerno):
	if lives >= 0:
		get_node("melee_ui").set_player_lives(playerno, lives)
		
func player_health(health, no):
	get_node("melee_ui").set_player_health(no, health)
	
func turn_off_processing():
	for player_node in get_node("players").get_children():
		player_node.set_fixed_process(false)
