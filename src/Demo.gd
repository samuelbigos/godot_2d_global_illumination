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
var _timer = 0.0
var _mouse_spawn = false

""" PUBLIC """

export var voronoi_buffer_scene : PackedScene = null
export var ball_scene : PackedScene = null
export var ball_frequency = 0.1

###########
# METHODS #
###########

""" PRIVATE """

func _ready():
	
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	$Screen/Screen.rect_size = get_viewport().size
	$SceneBuffer.set_size(get_viewport().size)
	
	_setup_voronoi_pipeline()
	_setup_GI_pipeline()
		
	# output to screen
	$Screen/Screen.get_material().set_shader_param("u_texture_to_draw", $GI.get_texture())
	
	$DebugRTT/SceneDebug.texture = $SceneBuffer.get_texture()
	$DebugRTT/EmissiveDebug.texture = GI.emissive_map.get_texture()
	$DebugRTT/AlbedoDebug.texture = GI.colour_map.get_texture()
	$DebugRTT/LastFrameDebug.texture = $LastFrameBuffer.get_texture()
	$DebugRTT/VoronoiDebug.texture = _voronoi_buffers[_voronoi_buffers.size() - 1].get_texture()
	$DebugRTT/DistanceFieldDebug.texture = $DistanceField.get_texture()
	$DebugRTT/VoronoiSeedDebug.texture = $VoronoiSeed.get_texture()
	
	_main_scene = $MainScene
	_light = $MainScene/Light
	remove_child($MainScene)
	$SceneBuffer.add_child(_main_scene)
	
	# set correct render pass order
	VisualServer.viewport_set_active(GI.emissive_map.get_viewport_rid(), false)
	VisualServer.viewport_set_active(GI.emissive_map.get_viewport_rid(), true)
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
	
	# setup initial control options
	_on_DistanceModSlider_value_changed(10.0)
	_on_RaysPerPixelSlider_value_changed(32)
	_on_EmissionMultiSlider_value_changed(1.5)
	_on_EmissionRangeSlider_value_changed(2.0)
	
func _process(delta):
	
	_timer += delta
	$GI.set_shader_param("u_time", _timer)
	
	_ball_timer -= delta
	if Input.is_action_pressed("ui_click") and not $Controls/TabContainer.get_rect().has_point(get_global_mouse_position()):
		if _mouse_spawn:
			if _ball_timer < 0.0:
				var ball = ball_scene.instance()
				_main_scene.add_child(ball)
				var sprite = ball.get_child(0)
			
				match _rng.randi_range(0, 4):
					0: 
						sprite.modulate = Color.aqua
					1: 
						sprite.modulate = Color.cornsilk
					2: 
						sprite.modulate = Color.fuchsia
					3: 
						sprite.modulate = Color.limegreen
					4: 
						sprite.modulate = Color.yellow
						
				var colour = Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized()
				sprite.modulate = Color(colour.x, colour.y, colour.z)
				sprite.set_emissive(1.0)
				sprite.set_colour(sprite.modulate)
			
				#ball.position = Vector2(_rng.randf_range(15.0, get_viewport().size.x - 15.0), 25.0)
				ball.position = get_global_mouse_position()
				_ball_timer = ball_frequency
		else:
			_light.position = get_global_mouse_position()
				
	$DebugRTT/FPS.text = String(Engine.get_frames_per_second())
		
func _setup_voronoi_pipeline():
	
	# voronoi
	$VoronoiSeed.set_size(get_viewport().size)
	$VoronoiSeed/Texture.get_material().set_shader_param("u_input_tex", $SceneBuffer.get_texture())
	$VoronoiSeed/Texture.rect_size = get_viewport().size
		
	var passes = log(max(get_viewport().size.x, get_viewport().size.y)) / log(2.0)
	
	for i in range(0, passes):
		var offset = pow(2, passes - i - 1)
		var buffer = voronoi_buffer_scene.instance()
		add_child(buffer)
		_voronoi_buffers.append(buffer)
		
		var input_texture = $VoronoiSeed.get_texture()
		if i > 0:
			input_texture = _voronoi_buffers[i - 1].get_texture()
			
		buffer.setup(i, passes, offset, input_texture, get_viewport().size)
		#print("setup voronoi with offset %d" % [offset])
	
	# distance field
	$DistanceField.set_size(get_viewport().size)
	$DistanceField/Texture.rect_size = get_viewport().size
	
	$DistanceField/Texture.get_material().set_shader_param("u_input_tex", _voronoi_buffers[passes - 1].get_texture())
	$DistanceField/Texture.get_material().set_shader_param("u_dist_mod", 10.0)
	
func _setup_GI_pipeline():

	# GI	
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
	
""" PUBLIC """

func _on_Final_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", $GI.get_texture())
func _on_Scene_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", $SceneBuffer.get_texture())
func _on_Colour_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", GI.colour_map.get_texture())
func _on_Emissive_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", GI.emissive_map.get_texture())
func _on_VoronoiSeed_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", $VoronoiSeed.get_texture())
func _on_VoronoiPass1_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", _voronoi_buffers[0].get_texture())
func _on_VoronoiPass2_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", _voronoi_buffers[1].get_texture())
func _on_VoronoiPass3_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", _voronoi_buffers[2].get_texture())
func _on_VoronoiPass4_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", _voronoi_buffers[3].get_texture())
func _on_VoronoiPass5_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", _voronoi_buffers[4].get_texture())
func _on_VoronoiPass6_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", _voronoi_buffers[5].get_texture())
func _on_VoronoiPass7_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", _voronoi_buffers[6].get_texture())
func _on_VoronoiPass8_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", _voronoi_buffers[7].get_texture())
func _on_VoronoiPass9_pressed(): $Screen/Screen.get_material().set_shader_param("texture_to_draw", _voronoi_buffers[8].get_texture())
func _on_DistanceField_pressed(): $Screen/Screen.get_material().set_shader_param("u_texture_to_draw", $DistanceField.get_texture())

func _on_RaysPerPixelSlider_value_changed(value):
	$GI.set_shader_param("u_rays_per_pixel", value)
	$Controls/TabContainer/Params/RaysPerPixel/RaysPerPixel.text = String(value)

func _on_LightBounceButton_toggled(button_pressed):
	$GI.set_shader_param("u_bounce", button_pressed)

func _on_DeNoiseButton_toggled(button_pressed):
	$GI.set_shader_param("u_denoise", button_pressed)

func _on_DistanceModSlider_value_changed(value):
	$GI.set_shader_param("u_dist_mod", value)
	$DistanceField/Texture.get_material().set_shader_param("u_dist_mod", value)
	$Controls/TabContainer/Params/DistanceMod/DistanceMod.text = "%05.2f" % value

func _on_FreezeButton_toggled(button_pressed):
	Engine.time_scale = 1.0 * int(!button_pressed)

func _on_EmissionMultiSlider_value_changed(value):
	$GI.set_shader_param("u_emission_multi", value)
	$Controls/TabContainer/Params/EmissionMulti/EmissionMulti.text = "%05.2f" % value

func _on_MouseSpawnButton_toggled(button_pressed):
	_mouse_spawn = button_pressed

func _on_EmissionRangeSlider_value_changed(value):
	$GI.set_shader_param("u_emission_range", value)
	$Controls/TabContainer/Params/EmissionRange/EmissionRange.text = "%05.2f" % value

func _on_EmissionDropoffSlider_value_changed(value):
	$GI.set_shader_param("u_emission_dropoff", value)
	$Controls/TabContainer/Params/EmissionDropoff/EmissionDropoff.text = "%05.2f" % value
