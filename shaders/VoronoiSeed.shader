shader_type canvas_item;

void fragment() 
{
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	
	// first make each pixel white unless it's fully black
	vec3 scene_col = texture(TEXTURE, SCREEN_UV).xyz;
	float x = scene_col.x + scene_col.y + scene_col.z;
	vec3 seed = ceil(vec3(x));
	
	// encode pixel position in vec4
	vec4 positions = vec4(UV.x, UV.y, 0.0, 1.0);
	
	// multiply with seed, which is black if not an occluder, so we don't colour every pixel
	COLOR = positions * vec4(seed, 1.0);
}