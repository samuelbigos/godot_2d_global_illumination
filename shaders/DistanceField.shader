shader_type canvas_item;

uniform sampler2D u_input_tex;
uniform float u_dist_mod = 1.0;

void fragment() 
{
	vec4 tex = texture(u_input_tex, UV);
	float dist = distance(tex.xy, UV);
	float mapped = clamp(dist * u_dist_mod, 0.0, 1.0);
	COLOR = vec4(vec3(mapped), 1.0);
}