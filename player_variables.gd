extends Node

const MAX_NUM_PLAYERS = 4

# PLAYER ENUM
const POSSUM = 0

var active_players
var selected_chars_players

func player_to_path(no):
	if no == POSSUM:
		return "res://players/possum.tscn"
	else:
		breakpoint

func _ready():
	print("player variables initializing")
	active_players = []
	active_players.resize(MAX_NUM_PLAYERS)
	
	selected_chars_players = []
	selected_chars_players.resize(MAX_NUM_PLAYERS)
	
	for i in range(MAX_NUM_PLAYERS):
		active_players[i] = false
		selected_chars_players[i] = -1
