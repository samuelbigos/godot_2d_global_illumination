extends Sprite
class_name GI_Sprite
"""
"""

###########
# MEMBERS #
###########

""" PRIVATE """

var _emissive = null
var _colour = null

""" PUBLIC """

###########
# METHODS #
###########

""" PRIVATE """

func _ready():
	_emissive = $EmissiveSprite
	_colour = $AlbedoSprite
	
	remove_child(_emissive)
	remove_child(_colour)
	GI.emissive_map.add_child(_emissive)
	GI.colour_map.add_child(_colour)
	
	_emissive.texture = texture
	_colour.texture = texture
	_emissive.scale = scale
	_colour.scale = scale
	_emissive.rotation = rotation
	_emissive.rotation = rotation
	
func _process(delta):
	_emissive.set_global_transform(get_global_transform())
	_colour.set_global_transform(get_global_transform())
	
""" PUBLIC """

func set_emissive(emissive):
	_emissive.modulate = Color(emissive, emissive, emissive)

func set_colour(colour):
	_colour.modulate = colour
