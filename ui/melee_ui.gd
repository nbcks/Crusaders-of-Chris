extends Node2D

const MAX_LIVES = 5
const MAX_DIGITS = 3

func _ready():
	# hide all the scores
	for node in get_node("scores/scores").get_children():
		node.hide()
	
func register_player(player_no, player_node):
	assert(player_node != null)
	get_node("scores/scores").get_child(player_no - 1).show()
	
	get_node("cam").add_player(player_node)
	
func activate_camera():
	get_node("cam").activate()
	
# give the player number 1 BASED (not 0th based)
# give the 
func set_player_lives(player_no, num_lives):
	var player_node = get_node("scores/scores/").get_child(player_no - 1)
	var lives = player_node.get_node("lives")
	
	assert(num_lives <= MAX_LIVES)
	assert(num_lives >= 0)
	
	var i = 0
	while i < MAX_LIVES:
		if i < num_lives:
			lives.get_child(i).show()
		else:
			lives.get_child(i).hide()
		i += 1
	

func set_player_health(player_no, health):
	var digits_health = convert_int_to_digits(health)
	var player_node = get_node("scores/scores/").get_child(player_no - 1)
	var numbers = player_node.get_node("number")
	
	var redun = get_redundant_digits(digits_health)
	if redun == MAX_DIGITS: # i.e if digits_health = [0, 0, 0]
		pass
	else:
		var i = redun # this tracks digits_health
		var dp = 0 # this tracks position in pictorial digits
		var pic
		while i < MAX_DIGITS:
			pic = num_to_pic(digits_health[i])
			numbers.get_child(dp).show()
			numbers.get_child(dp).set_texture(pic)
			i += 1
			dp += 1
		
		# set last digit to percentage
		numbers.get_child(dp).set_texture(percent)
		
		# hide the rest of the digits
		while dp < MAX_DIGITS:
			numbers.get_child(dp).hide()
			dp += 1
		
			
var zero = preload("res://art/numbers/0.png")
var one = preload("res://art/numbers/1.png")
var two = preload("res://art/numbers/2.png")
var three = preload("res://art/numbers/3.png")
var four = preload("res://art/numbers/4.png")
var five = preload("res://art/numbers/5.png")
var six = preload("res://art/numbers/6.png")
var seven = preload("res://art/numbers/7.png")
var eight = preload("res://art/numbers/8.png")
var nine = preload("res://art/numbers/9.png")
var percent = preload("res://art/numbers/percentage.png")
	
func num_to_pic(num):
	if num == 0:
		return zero
	elif num == 1:
		return one
	elif num == 2:
		return two
	elif num == 3:
		return three
	elif num == 4:
		return four
	elif num == 5:
		return five
	elif num == 6:
		return six
	elif num == 7:
		return seven
	elif num == 8:
		return eight
	elif num == 9:
		return nine
	else:
		breakpoint
		
# convert integer to 3 digits
func convert_int_to_digits(num):
	assert(num >= 0)
	
	var result = [0, 0, 0]
	
	if num >= 1000:
		return [9, 9, 9]
	else:
		result[0] = num / 100
		num = num % 100
		
		result[1] = num / 10
		num = num % 10
		
		result[2] = num
		
	return result 
	

# find the length of the digit string
# 00103 is length 3 for instance
func get_redundant_digits(digits):
	var len = digits.size()
	
	var i = 0
	while i < len:
		if digits[i] != 0:
			break
		else:
			i += 1
	
	return i
			
		
	
