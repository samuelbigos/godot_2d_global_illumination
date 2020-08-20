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
	
	$BackBuffer.set_shader_param("RESOLUTION", get_viewport().size)

func _process(delta):
	
	if Input.is_action_pressed("ui_click"):
		var mouse_pos = get_global_mouse_position() / get_viewport().size
		var aspect = get_viewport().size.x / get_viewport().size.y
		mouse_pos.x *= aspect
		$BackBuffer.set_shader_param("LIGHT_POS", -mouse_pos)
	
	$BackBuffer.set_shader_param("frame", _frame)
	_frame += 1

""" PUBLIC """
