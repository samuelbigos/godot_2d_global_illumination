shader_type canvas_item;

uniform sampler2D u_input_tex;

void fragment() 
{
	// for the voronoi seed texture we just store the UV of the pixel if the pixel is part
	// of an object (emissive or occluding), or black otherwise.
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec4 scene_col = texture(u_input_tex, UV);
	if(scene_col.a == 0.0)
	{
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	}
	else
	{
		COLOR = vec4(UV.x, UV.y, 0.0, 1.0);
	}
}