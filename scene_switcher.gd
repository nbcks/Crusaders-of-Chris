extends Node

var cur_scene = null


func goto_scene(path):
	
	# This function will usually be called from a signal callback,
	# or some other function from the running scene.
	# Deleting the current scene at this point might be
	# a bad idea, because it may be inside of a callback or function of it.
	# The worst case will be a crash or unexpected behavior.
	
	# The way around this is deferring the load to a later time, when
	# it is ensured that no code from the current scene is running:
	
	call_deferred("_deferred_goto_scene",path)


func _deferred_goto_scene(path):
	
	# Immediately free the current scene,
	# there is no risk here.
	cur_scene.free()
	
	# Load new scene
	var s = ResourceLoader.load(path)
	
	# Instance the new scene
	cur_scene = s.instance()
	
	# Add it to the active scene, as child of root
	get_tree().get_root().add_child(cur_scene)
	
	# optional, to make it compatible with the SceneTree.change_scene() API
	get_tree().set_current_scene( cur_scene )
	

func _ready():
	var root = get_tree().get_root()
	cur_scene = root.get_child( root.get_child_count() -1 )
