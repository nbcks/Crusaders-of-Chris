extends Camera2D

const ZOOM_FACTOR = 0.05
const MARGIN = 200.0
const MIN_ZOOM = 1

var players = []
func add_player(player):
	players.append(player)

func _process(delta):
	if players.empty():
		breakpoint
	var len = players.size()
	
	 # Create rectangle at pl1, then expand to fit pl2
	var rect = Rect2(players[0].get_pos(), Vector2())
	
	var i = 1
	while i < len:
		rect = rect.expand(players[i].get_pos())
		i += 1
	
	# Grow rectangle
		rect = rect.grow(MARGIN)
	
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
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
func activate():
	set_process(true)
