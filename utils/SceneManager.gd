extends Node

var hex_nodes := {}
var scene_nodes := {}


func setup(hex_root: Node, scene_dict: Dictionary):
	hex_nodes = {
		"Idle": hex_root.get_node_or_null("Idle"),
		"Money": hex_root.get_node_or_null("Money"),
	}
	scene_nodes = scene_dict
	_set_all_invisible()


func _set_all_invisible():
	for node in hex_nodes.values():
		node.visible = false
	for node in scene_nodes.values():
		node.visible = false


func show_scene(scene_name: String, hex_state: String = "Idle"):
	_set_all_invisible()

	if scene_nodes.has(scene_name):
		scene_nodes[scene_name].visible = true
	else:
		push_warning("Scene '%s' not found in SceneManager." % scene_name)

	if hex_nodes.has(hex_state):
		hex_nodes[hex_state].visible = true
	else:
		push_warning("Hex state '%s' not found in SceneManager." % hex_state)
