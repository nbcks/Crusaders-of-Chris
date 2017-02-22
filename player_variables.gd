extends Node

const MAX_NUM_PLAYERS = 8

# PLAYER ENUM
const POSSUM = 0

var active_players
var selected_chars_players

func _ready():
	active_players = []
	active_players.resize(MAX_NUM_PLAYERS)
	
	selected_chars_players = []
	selected_chars_players.resize(MAX_NUM_PLAYERS)
	
	for i in range(MAX_NUM_PLAYERS):
		active_players[i] = false
		selected_chars_players = -1
