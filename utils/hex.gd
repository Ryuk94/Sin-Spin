extends Node

# Called once in MainGame or a scene's _ready()
var hex_node: Node = null

func setup(hex_parent: Node):
	hex_node = hex_parent

func set_hex_state(state: String) -> void:
	if hex_node == null:
		push_error("Hex node not set. Call HexAppearance.setup() first.")
		return

	# Loop through all states and toggle visibility
	for child in hex_node.get_children():
		child.visible = child.name == state

	# Optional: you could add tweening or animation here if you want a smooth transition
