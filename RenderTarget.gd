extends Viewport
class_name RenderTarget
"""
Does XXX.
"""

###########
# MEMBERS #
###########

""" PRIVATE """

export var material : Material = null

""" PUBLIC """

###########
# METHODS #
###########

""" PRIVATE """

func _ready():
	$Canvas/Texture.material = material

""" PUBLIC """

func set_size(var in_size):
	size = in_size
	$Canvas/Texture.rect_size = in_size
	
func set_shader_param(param, val):
	$Canvas/Texture.get_material().set_shader_param(param, val)
