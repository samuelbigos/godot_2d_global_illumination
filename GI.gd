extends Node
"""
"""

###########
# MEMBERS #
###########

""" PRIVATE """

""" PUBLIC """

var emissive_map : Viewport
var albedo_map : Viewport

###########
# METHODS #
###########

""" PRIVATE """

func _ready():
	emissive_map = $EmissiveMap
	albedo_map = $AlbedoMap	
	emissive_map.set_size(get_viewport().size)
	albedo_map.set_size(get_viewport().size)

""" PUBLIC """
