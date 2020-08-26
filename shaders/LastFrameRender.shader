shader_type canvas_item;
render_mode skip_vertex_transform;

uniform sampler2D u_texture_to_draw;

void fragment() 
{
	vec4 sample = texture(u_texture_to_draw, UV);
	// clamp to 0-1 since we have HDR enabled on the viewport (which is necessary so Godot uses 16 byte
	// texture format). otherwise light will keep accumulating over multiple frames and blow out the scene.
	sample = min(vec4(1.0), sample);
	COLOR = vec4(sample);
}