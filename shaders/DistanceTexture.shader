shader_type canvas_item;
render_mode skip_vertex_transform;

void fragment() 
{
	COLOR = vec4(texture(TEXTURE, SCREEN_UV, 0.0));
}