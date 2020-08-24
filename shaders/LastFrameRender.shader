shader_type canvas_item;
render_mode skip_vertex_transform;

uniform sampler2D texture_to_draw : hint_black;

void fragment() 
{
	vec4 sample = texture(texture_to_draw, UV);
	COLOR = vec4(sample.rgb, sample.a);
}