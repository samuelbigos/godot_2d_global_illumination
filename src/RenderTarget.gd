extends Viewport
class_name RenderTarget
"""
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
	$Texture.material = material

""" PUBLIC """

func set_size(var in_size):
	size = in_size
	$Texture.rect_size = in_size
	
func set_material(mat):
	material = mat
	$Texture.material = material
	
func set_shader_param(param, val):
	$Texture.get_material().set_shader_param(param, val)
