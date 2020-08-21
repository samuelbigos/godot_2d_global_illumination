shader_type canvas_item;
render_mode skip_vertex_transform;

uniform sampler2D i_tex;
uniform float i_offset = 0.0; 
uniform float i_level = 0.0;
uniform float i_max_steps = 0.0;

void fragment() 
{
	float closest_dist = 9999999.9;
	vec2 closest_pos = vec2(0.0);
	
	for(float x = -1.0; x <= 1.0; x += 1.0)
	{
		for(float y = -1.0; y <= 1.0; y += 1.0)
		{
			vec2 voffset = UV;
			voffset += vec2(x, y) * SCREEN_PIXEL_SIZE * i_offset;

			vec2 pos = texture(i_tex, voffset).xy;
			float dist = distance(pos.xy, UV.xy);
			
			if(pos.x != 0.0 && pos.y != 0.0 && dist < closest_dist)
			{
				closest_dist = dist;
				closest_pos = pos;
			}
		}
	}
	//COLOR = texture(input_tex, UV);
	COLOR = vec4(closest_pos, 0.0, 1.0);
	
	/*
	float best_distance = 99999.0;
    vec2 best_coord = vec2(0.0);
	
	for (int y = -1; y <= 1; ++y) 
	{
        for (int x = -1; x <= 1; ++x) 
		{
            vec2 sample_coord = FRAGCOORD.xy + vec2(float(x), float(y)) * i_offset;
            
            vec4 data = texture(i_tex, (sample_coord) * SCREEN_PIXEL_SIZE);
            vec2 seed_coord = data.xy;
			
            float dist = distance(seed_coord / SCREEN_PIXEL_SIZE, FRAGCOORD.xy);
            if ((seed_coord.x != 0.0 || seed_coord.y != 0.0) && dist < best_distance)
            {
                best_distance = dist;
                best_coord = seed_coord;
            }
        }
    }
	
	COLOR = vec4(best_coord, 0.0, 1.0);
	*/
}