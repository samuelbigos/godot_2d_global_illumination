extends Viewport
class_name VoronoiBuffer
"""
"""

###########
# MEMBERS #
###########

""" PRIVATE """

""" PUBLIC """

###########
# METHODS #
###########

""" PRIVATE """

""" PUBLIC """

func setup(level, max_steps, offset, input, screen_size):
	$Texture.get_material().set_shader_param("i_level", level)
	$Texture.get_material().set_shader_param("i_max_steps", max_steps)
	$Texture.get_material().set_shader_param("i_offset", offset)
	$Texture.get_material().set_shader_param("i_tex", input)
	set_size(screen_size)
	$Texture.rect_size = screen_size
