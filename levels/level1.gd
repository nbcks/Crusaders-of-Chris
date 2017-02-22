extends Node

func player_health(health, no):
	get_node("ui/player%d_health" % no).set_text("player%d health: %d%%" % [no, health])

func _ready():
	# set player numbers
	var i = 0
	for player in get_node("players").get_children():
		i += 1
		player.set_player_no(i)
		player.connect("health_set", self, "player_health")
		player.connect("state_change", self, "change_state")
	
	get_node("blast_area").connect("body_enter", self, "chuck_to_centre")

	
func chuck_to_centre(body):
	body.set_pos(Vector2(500, 0))
	if body.has_method("set_health"):
		body.set_health(0)
	if body.has_method("set_velocity"):
		body.set_velocity(Vector2())
	
func change_state(state, playerno):
	print("player ", playerno, " ", get_node("players/possum1").state_name(state))
	
	