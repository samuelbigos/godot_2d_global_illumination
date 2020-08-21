shader_type canvas_item;
render_mode skip_vertex_transform;

uniform vec2 offset = vec2(0.0); 

void fragment() 
{
	float closest_dist = 9999999.9;
	vec2 closest_pos = vec2(0.0);
	vec2 pix = SCREEN_PIXEL_SIZE;
	for(float x = -1.0; x < 2.0; x += 1.0)
	{
		for(float y = -1.0; y < 2.0; y += 1.0)
		{
			vec2 pos = texture(TEXTURE, SCREEN_UV + vec2(x * float(offset) * pix.x, y * float(offset) * pix.y)).xy;
			if(pos.x + pos.y > 0.0)
			{
				float dist = distance(pos.xy, UV.xy);
				if(dist < closest_dist)
				{
					closest_dist = dist;
					closest_pos = pos;
				}
			}
		}
	}
	COLOR = vec4(closest_pos, 0.0, 1.0);
}