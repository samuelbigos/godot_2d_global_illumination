shader_type canvas_item;

uniform sampler2D input_tex;
uniform sampler2D scene_tex;

void fragment() 
{
	vec4 scene_col = texture(scene_tex, UV);
	if(scene_col.a > 0.0)
	{
		COLOR = scene_col;
	}
	else
	{
		float dist_max = 0.5;
		float dist_min = 0.0;
		
		vec4 tex = texture(input_tex, UV);
		float dist = distance(tex.xy, UV);
		float mapped = clamp(dist * 5.0, 0.0, 1.0);
		COLOR = vec4(vec3(mapped), 1.0);
	}
}