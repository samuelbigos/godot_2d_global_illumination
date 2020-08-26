extends Node2D
class_name Demo
"""
"""

###########
# MEMBERS #
###########

""" PRIVATE """

var _voronoi_buffers = []
var _ball_timer = 0.0
var _main_scene = null
var _light = null
var _rng
var _mouse_spawn = false
var _moving_debug = false
var _debug_init_pos = Vector2()
var _moving_debug_press_start = Vector2()
var _walls = []

""" PUBLIC """

export var rtt_scene : PackedScene = null
export var voronoi_mat : Material = null
export var ball_scene : PackedScene = null
export var ball_frequency = 0.1

###########
# METHODS #
###########

""" PRIVATE """

func _ready():
	
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	
	$SceneBuffer.set_size(get_viewport().size)
	
	_setup_voronoi_pipeline()
	_setup_GI_pipeline()
		
	# set default screen output to the final global illumination texture
	$Screen/Screen.rect_size = get_viewport().size
	$Screen/Screen.get_material().set_shader_param("u_texture_to_draw", $GI.get_texture())
	
	# move the scene to the correct viewport for rendering
	_walls.append($MainScene/Top)
	_walls.append($MainScene/Left)
	_walls.append($MainScene/Right)
	_main_scene = $MainScene
	_light = $MainScene/Light
	remove_child($MainScene)
	$SceneBuffer.add_child(_main_scene)
	
	# set correct render pass order
	# we need to do this because we created the voronoi pass viewports after the others (which were created on scene load)
	# which means they will be rendered after the others, which is no good
	# disabling and activating viewports on the VisualServer wil set the correct order
	VisualServer.viewport_set_active(GI.emissive_map.get_viewport_rid(), false)
	VisualServer.viewport_set_active(GI.emissive_map.get_viewport_rid(), true)
	VisualServer.viewport_set_active(GI.colour_map.get_viewport_rid(), false)
	VisualServer.viewport_set_active(GI.colour_map.get_viewport_rid(), true)
	VisualServer.viewport_set_active($SceneBuffer.get_viewport_rid(), false)
	VisualServer.viewport_set_active($SceneBuffer.get_viewport_rid(), true)
	VisualServer.viewport_set_active($VoronoiSeed.get_viewport_rid(), false)
	VisualServer.viewport_set_active($VoronoiSeed.get_viewport_rid(), true)
	for i in _voronoi_buffers:
		VisualServer.viewport_set_active(i.get_viewport_rid(), false)
		VisualServer.viewport_set_active(i.get_viewport_rid(), true)
	VisualServer.viewport_set_active($DistanceField.get_viewport_rid(), false)
	VisualServer.viewport_set_active($DistanceField.get_viewport_rid(), true)
	VisualServer.viewport_set_active($LastFrameBuffer.get_viewport_rid(), false)
	VisualServer.viewport_set_active($LastFrameBuffer.get_viewport_rid(), true)
	VisualServer.viewport_set_active($GI.get_viewport_rid(), false)
	VisualServer.viewport_set_active($GI.get_viewport_rid(), true)
	
	# disable default viewport render so we have the potential to update manually as an optimisation
	GI.emissive_map.render_target_update_mode = Viewport.UPDATE_ONCE
	GI.colour_map.render_target_update_mode = Viewport.UPDATE_ONCE
	$SceneBuffer.render_target_update_mode = Viewport.UPDATE_ONCE
	$VoronoiSeed.render_target_update_mode = Viewport.UPDATE_ONCE
	for i in _voronoi_buffers:
		i.render_target_update_mode = Viewport.UPDATE_ONCE
	$DistanceField.render_target_update_mode = Viewport.UPDATE_ONCE
	$LastFrameBuffer.render_target_update_mode = Viewport.UPDATE_ONCE
	$GI.render_target_update_mode = Viewport.UPDATE_ONCE
	
	# setup initial debug control options
	_on_DistanceModSlider_value_changed(5.0)
	_on_RaysPerPixelSlider_value_changed(32)
	_on_EmissionMultiSlider_value_changed(1.5)
	_on_EmissionRangeSlider_value_changed(2.0)
	_on_EmissionDropoffSlider_value_changed(2.0)
	_on_WallColourCheck_toggled(true)
	_on_DeNoiseButton_toggled(false)
	
func _process(delta):
	
	# debug menu blocks mouse
	var debug_blocking = $Controls/Control/TabContainer.get_global_rect().has_point(get_global_mouse_position()) and $Controls/Control/TabContainer.visible
	debug_blocking = debug_blocking or $Controls/Control/Minimise.get_global_rect().has_point(get_global_mouse_position())
	debug_blocking = debug_blocking or $Controls/Control/Move.get_global_rect().has_point(get_global_mouse_position())
	
	# spawn balls and move light
	_ball_timer -= delta
	if Input.is_action_pressed("ui_click") and not debug_blocking:
		if _mouse_spawn:			
			if _ball_timer < 0.0:
				var ball = ball_scene.instance()
				_main_scene.add_child(ball)
				var sprite = ball.get_child(0)
				var colour = Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized()
				sprite.modulate = Color(colour.x, colour.y, colour.z)
				sprite.set_emissive(1.0)
				sprite.set_colour(sprite.modulate)
				ball.position = get_global_mouse_position()
				_ball_timer = ball_frequency
		else:
			_light.position = get_global_mouse_position()
				
	$Screen/FPS.text = String(Engine.get_frames_per_second())
	
	# drag functionality of the debug menu.
	if _moving_debug:
		var mouse_delta = get_global_mouse_position() - _moving_debug_press_start
		$Controls/Control.rect_position = _debug_init_pos + mouse_delta
		if Input.is_action_just_released("ui_click"):
			_moving_debug = false
	
	# currently unused, but this is so we could potentially not draw viewports if nothing has changed
	# at the moment every viewport is set to UPDATE_ONCE every frame which is no different to UPDATE_ALWAYS
	var dirty = true
	if dirty:
		GI.emissive_map.render_target_update_mode = Viewport.UPDATE_ONCE
		GI.colour_map.render_target_update_mode = Viewport.UPDATE_ONCE
		$SceneBuffer.render_target_update_mode = Viewport.UPDATE_ONCE
		$VoronoiSeed.render_target_update_mode = Viewport.UPDATE_ONCE
		for i in _voronoi_buffers:
			i.render_target_update_mode = Viewport.UPDATE_ONCE
		$DistanceField.render_target_update_mode = Viewport.UPDATE_ONCE
	
	$LastFrameBuffer.render_target_update_mode = Viewport.UPDATE_ONCE
	$GI.render_target_update_mode = Viewport.UPDATE_ONCE
		
func _setup_voronoi_pipeline():
	
	$VoronoiSeed.set_size(get_viewport().size)
	$VoronoiSeed/Texture.get_material().set_shader_param("u_input_tex", $SceneBuffer.get_texture())
	$VoronoiSeed/Texture.rect_size = get_viewport().size
	
	# number of passes required is the log2 of the largest viewport dimension rounded up to the nearest power of 2
	# i.e. 768x512 is log2(1024) == 10
	var passes = ceil(log(max(get_viewport().size.x, get_viewport().size.y)) / log(2.0))
	for i in range(0, passes):
		# offset for each pass is half the previous one, starting at half the square resolution rounded up to nearest power 2
		# i.e. for 768x512 we round up to 1024x1024 and the offset for the first pass is 512x512, then 256x256, etc 
		var offset = pow(2, passes - i - 1)
		var buffer = rtt_scene.instance()
		add_child(buffer)
		_voronoi_buffers.append(buffer)
		
		# here we set the input texture for each pass, which is the previous pass, unless it's the first pass in which case it's
		# the seed texture
		var input_texture = $VoronoiSeed.get_texture()
		if i > 0:
			input_texture = _voronoi_buffers[i - 1].get_texture()
		
		buffer.set_size(get_viewport().size)
		buffer.set_material(voronoi_mat.duplicate())
		buffer.set_shader_param("u_level", i)
		buffer.set_shader_param("u_max_steps", passes)
		buffer.set_shader_param("u_offset", offset)
		buffer.set_shader_param("u_tex", input_texture)
	
	# setup the distance field size and input (which is the final voronoi pass)
	$DistanceField.set_size(get_viewport().size)
	$DistanceField/Texture.rect_size = get_viewport().size	
	$DistanceField/Texture.get_material().set_shader_param("u_input_tex", _voronoi_buffers[passes - 1].get_texture())
	$DistanceField/Texture.get_material().set_shader_param("u_dist_mod", 10.0)
	
func _setup_GI_pipeline():

	# set up GI material size and uniforms
	$LastFrameBuffer.set_size(get_viewport().size)
	$LastFrameBuffer.set_shader_param("u_texture_to_draw", $GI.get_texture())
	
	$GI.set_size(get_viewport().size)	
	$GI.set_shader_param("u_resolution", get_viewport().size)
	$GI.set_shader_param("u_distance_data", $DistanceField.get_texture())
	$GI.set_shader_param("u_scene_colour_data", GI.colour_map.get_texture())
	$GI.set_shader_param("u_scene_emissive_data", GI.emissive_map.get_texture())
	$GI.set_shader_param("u_last_frame_data", $LastFrameBuffer.get_texture())
	$GI.set_shader_param("u_dist_mod", 10.0)
	$GI.set_shader_param("u_rays_per_pixel", 32)

#
# This is all debug menu signal handling
#
func _on_Final_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", $GI.get_texture())
func _on_Scene_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", $SceneBuffer.get_texture())
func _on_Colour_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", GI.colour_map.get_texture())
func _on_Emissive_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", GI.emissive_map.get_texture())
func _on_VoronoiSeed_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", $VoronoiSeed.get_texture())
func _on_Voronoi_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", _voronoi_buffers[_voronoi_buffers.size() - 1].get_texture())
func _on_DistanceField_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", $DistanceField.get_texture())

func _on_RaysPerPixelSlider_value_changed(value):
	$GI.set_shader_param("u_rays_per_pixel", value)
	$Controls/Control/TabContainer/Params/RaysPerPixel/RaysPerPixel.text = String(value)
	$Controls/Control/TabContainer/Params/RaysPerPixel/RaysPerPixelSlider.value = value

func _on_LightBounceButton_toggled(button_pressed):
	$GI.set_shader_param("u_bounce", button_pressed)

func _on_DeNoiseButton_toggled(button_pressed):
	$GI.set_shader_param("u_denoise", button_pressed)

func _on_DistanceModSlider_value_changed(value):
	$GI.set_shader_param("u_dist_mod", value)
	$DistanceField/Texture.get_material().set_shader_param("u_dist_mod", value)
	$Controls/Control/TabContainer/Params/DistanceMod/DistanceMod.text = "%05.2f" % value
	$Controls/Control/TabContainer/Params/DistanceMod/DistanceModSlider.value = value

func _on_FreezeButton_toggled(button_pressed):
	Engine.time_scale = 1.0 * int(!button_pressed)

func _on_EmissionMultiSlider_value_changed(value):
	$GI.set_shader_param("u_emission_multi", value)
	$Controls/Control/TabContainer/Params/EmissionMulti/EmissionMulti.text = "%05.2f" % value
	$Controls/Control/TabContainer/Params/EmissionMulti/EmissionMultiSlider.value = value

func _on_MouseSpawnButton_toggled(button_pressed):
	_mouse_spawn = button_pressed

func _on_EmissionRangeSlider_value_changed(value):
	$GI.set_shader_param("u_emission_range", value)
	$Controls/Control/TabContainer/Params/EmissionRange/EmissionRange.text = "%05.2f" % value
	$Controls/Control/TabContainer/Params/EmissionRange/EmissionRangeSlider.value = value

func _on_EmissionDropoffSlider_value_changed(value):
	$GI.set_shader_param("u_emission_dropoff", value)
	$Controls/Control/TabContainer/Params/EmissionDropoff/EmissionDropoff.text = "%05.2f" % value
	$Controls/Control/TabContainer/Params/EmissionDropoff/EmissionDropoffSlider.value = value

func _on_Minimise_pressed():
	$Controls/Control/TabContainer.visible = !$Controls/Control/TabContainer.visible

func _on_Move_button_down():
	_moving_debug = true
	_debug_init_pos = $Controls/Control.rect_position
	_moving_debug_press_start = get_global_mouse_position()

func _on_Info_mouse_entered(extra_arg_0):
	$Controls/Tooltip.visible = true
	$Controls/Tooltip.rect_position = get_global_mouse_position() - Vector2($Controls/Tooltip.rect_size.x + 10.0, 10.0)
	
	if extra_arg_0 == 0:
		$Controls/Tooltip/Label.text = "Number of rays (light probes) sent out per pixel per frame. Each ray that hits an emissive surface adds to the brightness (and colour) of this pixel."
	if extra_arg_0 == 1:
		$Controls/Tooltip/Label.text = "Modifies maximum distance a ray travels in a step. See DistanceField RTT. Reducing this will reduce number of steps (thus samples) to reach surface, but reduce the precision to detect surface."
	if extra_arg_0 == 2:
		$Controls/Tooltip/Label.text = "Modifies emission so surfaces can be brighter than 1.0."
	if extra_arg_0 == 3:
		$Controls/Tooltip/Label.text = "Range of light. Increasing this will make light travel further before dimming."
	if extra_arg_0 == 4:
		$Controls/Tooltip/Label.text = "Light drop-off. Increasing this will make light get dimmer faster. Similar to range."
	if extra_arg_0 == 5:
		$Controls/Tooltip/Label.text = "Whether light bounces off surfaces. Due to the nature of the implementation, bounces are either off or infinite (i.e. until the bounced light is imperceptibly dim)."
	if extra_arg_0 == 6:
		$Controls/Tooltip/Label.text = "Whether to 'soften' the noise by averaging with previous frames. Not particularly effective at the moment."
	if extra_arg_0 == 7:
		$Controls/Tooltip/Label.text = "Reduce time_scale to 0, also stops the time-based ray direction randomisation, so noise will also freeze."
	if extra_arg_0 == 8:
		$Controls/Tooltip/Label.text = "Toggles between the mouse moving the single point light, and spawning multicoloured balls."
	if extra_arg_0 == 9:
		$Controls/Tooltip/Label.text = "(A) Coloured walls. (B) White walls. (C) Black walls. The more saturated the colour, the more light of that colour will be bounced. The algorithm could be improved to mix the incoming light with the surface colour. At the moment, walls will only radiate their colour."
			
func _on_Info_mouse_exited():
	$Controls/Tooltip.visible = false
	$Controls/Tooltip.rect_size = Vector2(0.0, 0.0)
	$Controls/Tooltip/Label.rect_size = Vector2(0.0, 0.0)

func _on_WallColourCheck_toggled(button_pressed):
	_walls[0].set_colour(Color.red)
	_walls[1].set_colour(Color.yellow)
	_walls[2].set_colour(Color.teal)

func _on_WallWhiteCheck_toggled(button_pressed):
	_walls[0].set_colour(Color(1.0, 1.0, 1.0, 1.0))
	_walls[1].set_colour(Color(1.0, 1.0, 1.0, 1.0))
	_walls[2].set_colour(Color(1.0, 1.0, 1.0, 1.0))

func _on_WallBlackCheck_toggled(button_pressed):
	_walls[0].set_colour(Color.black)
	_walls[1].set_colour(Color.black)
	_walls[2].set_colour(Color.black)

""" PUBLIC """
