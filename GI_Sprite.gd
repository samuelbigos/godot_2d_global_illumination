extends Sprite
class_name GI_Sprite
"""
"""

###########
# MEMBERS #
###########

""" PRIVATE """

var _emissive = null
var _albedo = null

""" PUBLIC """

###########
# METHODS #
###########

""" PRIVATE """

func _ready():
	_emissive = $EmissiveSprite
	_albedo = $AlbedoSprite
	
	remove_child(_emissive)
	remove_child(_albedo)
	GI.emissive_map.add_child(_emissive)
	GI.albedo_map.add_child(_albedo)
	
	_emissive.texture = texture
	_albedo.texture = texture
	_emissive.scale = scale
	_albedo.scale = scale
	_emissive.rotation = rotation
	_emissive.rotation = rotation
	
func _process(delta):
	_emissive.set_global_transform(get_global_transform())
	_albedo.set_global_transform(get_global_transform())
	
""" PUBLIC """

func set_emissive(emissive):
	_emissive.modulate = Color(emissive, emissive, emissive)

func set_albedo(albedo):
	_albedo.modulate = albedo
