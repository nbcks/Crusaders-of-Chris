extends Camera2D

const ZOOM_FACTOR = 0.05
const MARGIN = 200.0

func test():
	var zoomin = Input.is_action_pressed("zoom_in")
	var zoomout = Input.is_action_pressed("zoom_out")
	
	var cur_zoom = get_zoom()
	
	if zoomin:
		print ("zoom in setting")
		set_zoom(cur_zoom * (1 + ZOOM_FACTOR))
	elif zoomout:
		print("zoom out setting")
		set_zoom(cur_zoom / (1 + ZOOM_FACTOR))
		
	print(get_camera_pos())
		
func test2():
	var minx = pow(2, 30)
	var maxx = -pow(2, 30)
	var miny = pow(2, 30)
	var maxy = -pow(2, 30)
	
	var level = get_parent()
	
	for player in level.get_node("players").get_children():
		#print(player.get_name(), "player pos: ", player.get_pos())
		#print("maxx: ", maxx)
		var pos = player.get_pos()
		minx = min (minx, pos.x)
		miny = min (miny, pos.y)
		
		maxx = max (maxx, pos.x)
		maxy = max (maxy, pos.y)
		
	minx = minx
	maxx = maxx
	
	miny = miny
	maxy = maxy
	
		
	var p1 = Vector2(minx, miny) 
	var p2 = Vector2(maxx, miny)
	var p3 = Vector2(minx, maxy)
	var p4 = Vector2(maxx, maxy)
	
	var new_cam_pos = Vector2((maxx + minx)/2, (maxy + miny)/2)
	
	set_pos(new_cam_pos)
		
	#print("max x: ", maxx, " max y: ", maxy, " min x: ", minx, " min y: ", miny)

var p1 = Vector3()
var p2 = Vector3()
var cam = Vector3()

func internet_script(delta):
	# get the two points
	var p1_2d = get_parent().get_node("players/possum1").get_pos()
	var p2_2d = get_parent().get_node("players/possum2").get_pos()
	
	p1 = get_node("../player").get_translation()
	p2 = get_node("../enemy").get_translation()
	# set the minimal Y
	if (p1.y < p2.y): p2.y = p1.y
	else: p1.y = p2.y
	# calculate the center between p1 & p2
	var c = Vector3()
	c.y = p1.y
	c.x = (p2.x - p1.x)/2 + p1.x
	c.z = (p2.z - p1.z)/2 + p1.z
	# calculate the translation of the camera
	var d = p1.distance_to(p2)*0.9
	if (d < 9): d = 9
	# calculate the two possible positions
	var a2 = -1 / ((p1.z - p2.z) / (p1.x - p2.x))
	var m2 = c.z - a2*c.x
	var ca = 1 + a2*a2
	var cb = 2*a2*m2 - 2*c.x - 2*c.z*a2
	var cc = c.x*c.x + c.z*c.z + m2*m2 - d*d - 2*c.z*m2
	var delta = cb*cb - 4*ca*cc
	var r1 = (-cb-sqrt(delta))/(2*ca)
	var r2 = (-cb+sqrt(delta))/(2*ca)
	var cm = Vector3(r1,c.y+d*0)
	
func test5():
	var p1 = get_parent().get_node("players/possum1").get_pos()
	var p2 = get_parent().get_node("players/possum2").get_pos()
	
	var cam_pos = Vector2((p1.x + p2.x)/2, (p1.y + p2.y)/2)
	
	set_pos(cam_pos)
	
	
var CAMERA_MARGIN = 64 * 6 # Number of pixels to expand the rectangle
var MIN_ZOOM = 1 # Minimum zoom, so if players are close, it wont zoom in too much	
func test6():
	var pl1 = get_parent().get_node("players/possum1").get_pos()
	var pl2 = get_parent().get_node("players/possum2").get_pos()
	
	 # Create rectangle at pl1, then expand to fit pl2
	var rect = Rect2(pl1, Vector2())
	rect = rect.expand(pl2)
	
	# Grow rectangle
	rect = rect.grow(CAMERA_MARGIN)
	
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

func _process(delta):
	test6()
	pass

	
func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
