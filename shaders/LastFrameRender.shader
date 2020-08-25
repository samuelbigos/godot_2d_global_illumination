shader_type canvas_item;
render_mode skip_vertex_transform;

uniform sampler2D u_texture_to_draw;

void fragment() 
{
	vec4 sample = texture(u_texture_to_draw, UV);
	sample = min(vec4(1.0), sample);
	COLOR = vec4(sample);
}