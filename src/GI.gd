extends Node
"""
"""

###########
# MEMBERS #
###########

""" PRIVATE """

""" PUBLIC """

var emissive_map : Viewport
var colour_map : Viewport

###########
# METHODS #
###########

""" PRIVATE """

func _ready():
	emissive_map = $EmissiveMap
	colour_map = $ColourMap	
	emissive_map.set_size(get_viewport().size)
	colour_map.set_size(get_viewport().size)

""" PUBLIC """
