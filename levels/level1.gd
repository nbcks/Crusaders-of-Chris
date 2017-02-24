extends Node

var player_vars
var no_players = 0

var players

func player_health(health, no):
	get_node("melee_ui").set_player_health(no, health)

func _ready():
	player_vars = get_node("/root/player_variables")
	var active_players = player_vars.active_players
	var selected_chars_players = player_vars.selected_chars_players
	
	players = []
	players.resize(player_vars.MAX_NUM_PLAYERS)
	for i in range(player_vars.MAX_NUM_PLAYERS):
		players[i] = {
			"active" : false,
			"health" : 0,
			"lives" : 0
		}
	
	var i = 0
	var player
	var path
	for active in active_players:
		if active:
			path = player_vars.player_to_path(selected_chars_players[i])
			player = ResourceLoader.load(path).instance()
			
			get_node("players").add_child(player)
			player.set_global_pos(get_node("spawns").get_child(i).get_global_pos())
			
			players[i]["active"] = true
			players[i]["health"] = 0
			players[i]["lives"] = 5
			
			
			var player_no = i + 1
			player.set_player_no(player_no)
			player.set_lives(5)
			
			player.connect("lives_set", self, "player_lives")
			player.connect("health_set", self, "player_health")
			player.connect("state_change", self, "change_state")
		
			var melee_ui = get_node("melee_ui")
			melee_ui.register_player(player_no, player)
			melee_ui.set_player_health(player_no, 0)
			melee_ui.set_player_lives(player_no, 5)
			
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
			if body.lives > 0:
				body.set_lives(body.lives - 1)
			else:
				print("player: ", body.player_no, " eliminated!")
				body.queue_free()
	
func change_state(state, playerno):
	if get_node("players").get_child_count() > 0:
		print("player ", playerno, " ", get_node("players").get_child(0).state_name(state))
	else:
		breakpoint
	
func player_lives(lives, playerno):
	if lives >= 0:
		get_node("melee_ui").set_player_lives(playerno, lives)
	
	