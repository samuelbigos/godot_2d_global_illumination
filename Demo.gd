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

var _update_time = 2.0
var _gi_update_timer = 0.0
var _last_update_timer = _update_time * 0.5

""" PUBLIC """

export var voronoi_buffer_scene : PackedScene = null
export var ball_scene : PackedScene = null
export var ball_frequency = 0.025

###########
# METHODS #
###########

""" PRIVATE """

func _ready():
	
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	$CanvasLayer/Screen.rect_size = get_viewport().size

	#$DebugRTT/BG.rect_size = get_viewport().size * 0.5
	#$DebugRTT/SceneDebug.rect_size = get_viewport().size * 0.5
	#$DebugRTT/LastFrameDebug.rect_size = get_viewport().size * 0.5
	#$DebugRTT/VoronoiDebug.rect_size = get_viewport().size * 0.5
	#$DebugRTT/VoronoiSeedDebug.rect_size = get_viewport().size * 0.5
	#$DebugRTT/DistanceFieldDebug.rect_size = get_viewport().size * 0.5
	
	$SceneBuffer.set_size(get_viewport().size)
	
	_setup_voronoi_pipeline()
	_setup_GI_pipeline()
		
	# output to screen
	$CanvasLayer/Screen.get_material().set_shader_param("texture_to_draw", $BackBuffer.get_texture())
	#$CanvasLayer/Screen.get_material().set_shader_param("texture_to_draw", _voronoi_buffers[_voronoi_buffers.size() - 1].get_texture())
	
	$DebugRTT/SceneDebug.texture = $SceneBuffer.get_texture()
	$DebugRTT/LastFrameDebug.texture = $LastFrameBuffer.get_texture()
	$DebugRTT/VoronoiDebug.texture = _voronoi_buffers[_voronoi_buffers.size() - 1].get_texture()
	$DebugRTT/DistanceFieldDebug.texture = $DistanceField.get_texture()
	$DebugRTT/VoronoiSeedDebug.texture = $VoronoiSeed.get_texture()
	
	_main_scene = $MainScene
	_light = $MainScene/Light
	var pinjoint = $MainScene/PinJoint2D
	remove_child($MainScene)
	$SceneBuffer.add_child(_main_scene)
	pinjoint.node_a = pinjoint.get_children()[0].get_path()
	pinjoint.node_b = pinjoint.get_children()[1].get_path()
	
	# set correct render pass order
	var index = 0
	move_child($SceneBuffer, index)
	index += 1
	move_child($VoronoiSeed, index)
	index += 1
	for i in _voronoi_buffers:
		move_child(i, index)
		index += 1
	move_child($DistanceField, index)
	index += 1
	move_child($LastFrameBuffer, index)
	index += 1
	move_child($BackBuffer, index)
	index += 1
	
func _process(delta):
	
	_ball_timer -= delta
	if Input.is_action_pressed("ui_click"):
		
		"""
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
			
			#ball.position = Vector2(_rng.randf_range(15.0, get_viewport().size.x - 15.0), 25.0)
			ball.position = get_global_mouse_position()
			_ball_timer = ball_frequency
		"""
		
		_light.position = get_global_mouse_position()
	
	$DebugRTT/Label.text = String(Engine.get_frames_per_second())
	$DebugRTT/Label.text = String(_gi_update_timer)
	
	_gi_update_timer -= delta
	if _gi_update_timer < 0.0:
		$SceneBuffer.render_target_update_mode = Viewport.UPDATE_ONCE
		$BackBuffer.render_target_update_mode = Viewport.UPDATE_ONCE
		$VoronoiSeed.render_target_update_mode = Viewport.UPDATE_ONCE
		for i in _voronoi_buffers:
			i.render_target_update_mode = Viewport.UPDATE_ONCE
		$DistanceField.render_target_update_mode = Viewport.UPDATE_ONCE
		$LastFrameBuffer.render_target_update_mode = Viewport.UPDATE_ONCE
		$BackBuffer.render_target_update_mode = Viewport.UPDATE_ONCE
		_gi_update_timer = _update_time
		
	_last_update_timer -= delta
	if _last_update_timer < 0.0:
		#$LastFrameBuffer.render_target_update_mode = Viewport.UPDATE_ONCE
		_last_update_timer = _update_time
		
func _setup_voronoi_pipeline():
	
	# voronoi
	$VoronoiSeed.set_size(get_viewport().size)
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
	
	$DistanceField/Texture.get_material().set_shader_param("input_tex", _voronoi_buffers[passes - 1].get_texture())
	$DistanceField/Texture.get_material().set_shader_param("dist_mod", 10.0)
	
func _setup_GI_pipeline():

	# GI	
	$LastFrameBuffer.set_size(get_viewport().size)
	$LastFrameBuffer.set_shader_param("texture_to_draw", $BackBuffer.get_texture())
	
	$BackBuffer.set_size(get_viewport().size)	
	$BackBuffer.set_shader_param("resolution", get_viewport().size)
	$BackBuffer.set_shader_param("distance_data", $DistanceField.get_texture())
	$BackBuffer.set_shader_param("scene_data", $SceneBuffer.get_texture())
	$BackBuffer.set_shader_param("last_frame_data", $LastFrameBuffer.get_texture())
	$BackBuffer.set_shader_param("dist_mod", 10.0)
	
""" PUBLIC """
