extends Camera2D

const ZOOM_FACTOR = 0.05
const MARGIN = 200.0
const MIN_ZOOM = 1

var players
var active_player_array
var act_play_len = 0
var min_point
var max_point

func active_players():
	act_play_len = 0
	for player in players:
		if player["active"]:
			active_player_array[act_play_len] = player["node"]
			act_play_len += 1

func _process(delta):
	# Create rectangle at pl1, then expand to fit pl2
	
	active_players()
	
	var rect
	var len
	if act_play_len <= 0:
		breakpoint
	else:
		rect = Rect2(active_player_array[0].get_global_pos(), Vector2())

	var i = 1
	while i < act_play_len:
		rect = rect.expand(active_player_array[i].get_global_pos())
		i += 1
	
	# Grow rectangle
	rect = rect.grow(MARGIN)
	
	# make sure it never goes over min or max point
	rect.pos.x = max(min_point.x, rect.pos.x)
	rect.pos.y = max(min_point.y, rect.pos.y)
	
	rect.pos.x = min(max_point.x, rect.pos.x)
	rect.pos.y = min(max_point.y, rect.pos.y)
	
	if rect.size.x + rect.pos.x > max_point.x:
		rect.size.x = max_point.x - rect.pos.x
	
	if rect.size.y + rect.pos.y > max_point.y:
		rect.size.y = max_point.y - rect.pos.y
		
	# Find the width and height scale, then choose the smallest one
	var window_size = OS.get_window_size()
	#print("window size: ", window_size)
	var scale_w = window_size.x / rect.size.x
	var scale_h = window_size.y / rect.size.y
	var scale = 1 / min(scale_w, scale_h)
	
	# Limit the zoom
	scale = max(MIN_ZOOM, scale)
	
	# Set zoom and position
	set_zoom(Vector2(scale, scale))
	set_pos(rect.pos + (rect.size * 0.5))

	
func _ready():
	players = get_node("/root/player_variables").players
	
	active_player_array = []
	active_player_array.resize(get_node("/root/player_variables").MAX_NUM_PLAYERS)
	act_play_len = 0
	
	
	
func activate(min_point, max_point):
	self.min_point = min_point
	self.max_point = max_point
	set_process(true)
