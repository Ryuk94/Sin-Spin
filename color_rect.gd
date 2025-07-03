extends ColorRect


#Balatro style

#func _ready():
	## Set the screen_size uniform when the node is ready.
	## This ensures it's correct on game start.
	#(material as ShaderMaterial).set_shader_parameter("screen_size", get_viewport_rect().size)
#
	## You can also set other uniforms here, for example, to make it rotate
	## (material as ShaderMaterial).set_shader_parameter("is_rotating", true)
#
#func _process(delta):
	## If you want the shader to react to window resizing, you can update it here.
	## For a static background, _ready() is often enough.
	#(material as ShaderMaterial).set_shader_parameter("screen_size", get_viewport_rect().size)
#
	## If you want to dynamically turn rotation on/off
	#if Input.is_action_just_pressed("ui_accept"):
		#var current_state = (material as ShaderMaterial).get_shader_parameter("is_rotating")
		#(material as ShaderMaterial).set_shader_parameter("is_rotating", !current_state)


#Succubus style

func _ready():
	# Ensure the material is a ShaderMaterial
	if material is ShaderMaterial:
		# Set the screen_size on startup
		(material as ShaderMaterial).set_shader_parameter("screen_size", get_viewport_rect().size)

func _process(_delta):
	# Update the screen_size every frame to handle window resizing
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("screen_size", get_viewport_rect().size)
