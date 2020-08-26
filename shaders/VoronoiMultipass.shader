shader_type canvas_item;
render_mode skip_vertex_transform;

uniform sampler2D u_tex;
uniform float u_offset = 0.0; 
uniform float u_level = 0.0;
uniform float u_max_steps = 0.0;

void fragment() 
{
	float closest_dist = 9999999.9;
	vec2 closest_pos = vec2(0.0);
	
	// uses Jump Flood Algorithm to do a fast voronoi generation.
	for(float x = -1.0; x <= 1.0; x += 1.0)
	{
		for(float y = -1.0; y <= 1.0; y += 1.0)
		{
			vec2 voffset = UV;
			voffset += vec2(x, y) * SCREEN_PIXEL_SIZE * u_offset;

			vec2 pos = texture(u_tex, voffset).xy;
			float dist = distance(pos.xy, UV.xy);
			
			if(pos.x != 0.0 && pos.y != 0.0 && dist < closest_dist)
			{
				closest_dist = dist;
				closest_pos = pos;
			}
		}
	}
	COLOR = vec4(closest_pos, 0.0, 1.0);
}