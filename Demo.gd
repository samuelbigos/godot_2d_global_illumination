extends Node2D

const UPDATE_TIME = 0.0

var frame = -1
var update_fb_timer = UPDATE_TIME
var update_bb_timer = UPDATE_TIME * 0.5

func _process(delta):
	
	if Input.is_action_pressed("ui_click"):
		var mouse_pos = get_global_mouse_position() - get_viewport_rect().size * 0.5
		$Viewport/PostProcess/GI.get_material().set_shader_param("LIGHT_POS", mouse_pos)
	
	update_fb_timer -= delta
	if update_fb_timer < 0.0:
		frame += 1
		$Viewport/PostProcess/GI.get_material().set_shader_param("frame", frame)
		$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		update_fb_timer = UPDATE_TIME
		
	update_bb_timer -= delta
	if update_bb_timer < 0.0:
		frame += 1
		$BackBuffer.render_target_update_mode = Viewport.UPDATE_ONCE
		update_bb_timer = UPDATE_TIME
