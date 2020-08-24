shader_type canvas_item;

uniform sampler2D input_tex;
uniform float dist_mod = 2.0;

void fragment() 
{
	vec4 tex = texture(input_tex, UV);
	float dist = distance(tex.xy, UV);
	float mapped = clamp(dist * dist_mod, 0.0, 1.0);
	COLOR = vec4(vec3(mapped), 1.0);
}