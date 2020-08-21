extends Node2D
class_name Demo
"""
"""

###########
# MEMBERS #
###########

""" PRIVATE """

var _frame = 0

""" PUBLIC """

export var voronoi_buffer_scene : PackedScene = null

###########
# METHODS #
###########

""" PRIVATE """

func _ready():
	$BackBuffer.set_size(get_viewport().size)	
	$LastFrameBuffer.set_size(get_viewport().size)
	$CanvasLayer/Screen.rect_size = get_viewport().size
	$DebugRTT/LastFrameBG.rect_size = get_viewport().size * 0.5
	$DebugRTT/LastFrameBuffer.rect_size = get_viewport().size * 0.5
	$SceneBuffer.set_size(get_viewport().size)
	
	$BackBuffer.set_shader_param("RESOLUTION", get_viewport().size)
		
	_setup_voronoi_pipeline()
	_setup_GI_pipeline()
		
	# output to screen
	$CanvasLayer/Screen.get_material().set_shader_param("texture_to_draw", $DistanceField.get_texture())
	
func _process(delta):
	
	if Input.is_action_pressed("ui_click"):
		var mouse_pos = get_global_mouse_position() / get_viewport().size
		var aspect = get_viewport().size.x / get_viewport().size.y
		mouse_pos.x *= aspect
		$BackBuffer.set_shader_param("LIGHT_POS", -mouse_pos)
	
	$BackBuffer.set_shader_param("frame", _frame)
	_frame += 1
	
	$DebugRTT/Label.text = String(Engine.get_frames_per_second())
		
func _setup_voronoi_pipeline():
	
	# voronoi
	$VoronoiSeed.render_target_update_mode = Viewport.UPDATE_ALWAYS
	$VoronoiSeed.set_size(get_viewport().size)
	$VoronoiSeed/Texture.rect_size = get_viewport().size
		
	var passes = log(max(get_viewport().size.x, get_viewport().size.y)) / log(2.0)
	var buffers = []
	
	for i in range(0, passes):
		var offset = pow(2, passes - i - 1)
		var buffer = voronoi_buffer_scene.instance()
		add_child(buffer)
		buffers.append(buffer)
		
		var input_texture = $VoronoiSeed.get_texture()
		if i > 0:
			input_texture = buffers[i - 1].get_texture()
			
		buffer.setup(i, passes, offset, input_texture, get_viewport().size)
		print("setup voronoi with offset %d" % [offset])
	
	# distance field
	$DistanceField.render_target_update_mode = Viewport.UPDATE_ALWAYS
	$DistanceField.set_size(get_viewport().size)
	$DistanceField/Texture.rect_size = get_viewport().size
	
	$DistanceField/Texture.get_material().set_shader_param("input_tex", buffers[passes - 1].get_texture())
	$DistanceField/Texture.get_material().set_shader_param("scene_tex", $SceneBuffer.get_texture())
	
func _setup_GI_pipeline():
	
	# GI
	$BackBuffer.set_shader_param("in_data", $DistanceField)
	
""" PUBLIC """
