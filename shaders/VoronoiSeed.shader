shader_type canvas_item;

uniform sampler2D input_tex;

void fragment() 
{
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	
	// first make each pixel white unless it's fully black
	vec4 scene_col = texture(input_tex, UV);
	if(scene_col.r == 0.0 && scene_col.g == 0.0 && scene_col.b == 0.0)
	{
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
	else
	{
		COLOR = vec4(UV.x, UV.y, 0.0, 1.0);
	}
}