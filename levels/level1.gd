extends Node

var player_vars
var no_players = 0

func player_health(health, no):
	get_node("ui/player%d_health" % no).set_text("player%d health: %d%%" % [no, health])

func _ready():
	player_vars = get_node("/root/player_variables")
	var active_players = player_vars.active_players
	var selected_chars_players = player_vars.selected_chars_players
	
	var i = 0
	var player
	var path
	for active in active_players:
		if active:
			path = player_vars.player_to_path(selected_chars_players[i])
			player = ResourceLoader.load(path).instance()
			
			get_node("players").add_child(player)
			player.set_global_pos(get_node("spawns").get_child(i).get_global_pos())
			player.set_player_no(i+1)
			print("set player no: %d" % (i + 1))
			
			player.connect("health_set", self, "player_health")
			player.connect("state_change", self, "change_state")
		
			var melee_ui = get_node("melee_ui")
			melee_ui.register_player(i + 1, player)
			melee_ui.set_player_health(i + 1, 0)
			melee_ui.set_player_lives(i + 1, 5)
			
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
	
func change_state(state, playerno):
	#print("player ", playerno, " ", get_node("players/possum1").state_name(state))
	pass
	