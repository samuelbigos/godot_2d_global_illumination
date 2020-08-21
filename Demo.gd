extends Node2D
class_name Demo
"""
Does XXX.
"""

###########
# MEMBERS #
###########

""" PRIVATE """

var _frame = 0

""" PUBLIC """

export var voronoi_multipass_material : Material = null

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
	
	$VPC/DistanceBuffer.set_size(get_viewport().size)
	$VPC/DistanceBuffer/VPC/VoronoiBuffer.set_size(get_viewport().size)
	
	$BackBuffer.set_shader_param("RESOLUTION", get_viewport().size)
	
	get_viewport().render_target_update_mode = Viewport.UPDATE_DISABLED
	$BackBuffer.render_target_update_mode = Viewport.UPDATE_DISABLED
	$LastFrameBuffer.render_target_update_mode = Viewport.UPDATE_DISABLED
	$VPC/DistanceBuffer.render_target_update_mode = Viewport.UPDATE_DISABLED
	$VPC/DistanceBuffer/VPC/VoronoiBuffer.render_target_update_mode = Viewport.UPDATE_DISABLED

func _process(delta):
	
	if Input.is_action_pressed("ui_click"):
		var mouse_pos = get_global_mouse_position() / get_viewport().size
		var aspect = get_viewport().size.x / get_viewport().size.y
		mouse_pos.x *= aspect
		$BackBuffer.set_shader_param("LIGHT_POS", -mouse_pos)
	
	$BackBuffer.set_shader_param("frame", _frame)
	_frame += 1
	
	$DebugRTT/Label.text = String(Engine.get_frames_per_second())
	
	_render_voronoi()
	
func _render_voronoi():
	
	var resolution = get_viewport().size
	var offset = pow()
	
	#get_viewport().render_target_update_mode = Viewport.UPDATE_ONCE
	VisualServer.force_draw(true)

""" PUBLIC """
