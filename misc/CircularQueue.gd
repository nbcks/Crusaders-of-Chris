
const QUEUE_SIZE = 10000

var pos = 0

var buffer = []

func _init():
	print("circular queue initialized")
	buffer = []
	buffer.resize(QUEUE_SIZE)

# add 
func add_ctrls(ctrl_object):
	buffer[pos] = ctrl_object
	pos = (pos + 1) % QUEUE_SIZE
	
func get_last_ctrl(i):
	var p = spec_mod(pos - (i + 1)) # 0 is the current ctrl, 1 the last
	return buffer[p]

# get the last x control dictionarys corresponding to the last 
# x frames
func get_last_x_ctrls(x):
	var result = []
	result.resize(x)
	var p = pos - x
	if p < 0:
		p = QUEUE_SIZE + p
	
	for i in range(x):
		result[i] = buffer[(p + i) % QUEUE_SIZE]
		
	return result
	
func spec_mod(i):
	if i < 0:
		return QUEUE_SIZE - 1
	else:
		return i

# how many frames has the ctrl been pressed for
# from back presses back
func how_long_pressed_from(ctrl, back):
	var i = 0
	var p = spec_mod(pos - back) # pos - 1 is the position of last key pressed
	
	while (i < QUEUE_SIZE):
		p = spec_mod(p - 1)
		if buffer[p][ctrl]:
			i += 1
		else:
			break
		
	return i
		
	
	
func test_fill_ints():
	for i in range(10000):
		buffer[i] = i