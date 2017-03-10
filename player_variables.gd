extends Node

const MAX_NUM_PLAYERS = 5

# PLAYER ENUM
const POSSUM = 0
const CHRIS = 1
const ANAND_DAD = 2

var players

# if more than two players are alive, returns - 1
# else returns the player_no
func player_won():
	var first_player = true
	var first_player_index = -1
	var no_players = 0
	var i = 0
	
	while i < MAX_NUM_PLAYERS:
		print(players[i])
		if players[i]["alive"]:
			if first_player:
				first_player = false
				first_player_index = i
			no_players += 1
		i += 1
	
	if no_players >= 2:
		return -1
	elif no_players == 1:
		return first_player_index + 1
	else:
		breakpoint
			
		

func player_to_path(no):
	if no == POSSUM:
		return "res://players/possum.tscn"
	elif no == CHRIS:
		return "res://players/chris.tscn"
	elif no == ANAND_DAD:
		return "res://players/anand_dad.tscn"
	else:
		breakpoint

func set_possum_2():
	players[0]["active"] = true
	players[0]["character"] = POSSUM
	players[1]["active"] = true
	players[1]["character"] = POSSUM

func _ready():
	print("player variables initializing")
	
	players = []
	players.resize(MAX_NUM_PLAYERS)
	
	for i in range(MAX_NUM_PLAYERS):
		players[i] = {
			"health" : 0,
			"lives" : 0,
			"character" : -1,
			"alive" : false,
			"active" : false,
			"node" : null
		}
