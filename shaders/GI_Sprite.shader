shader_type canvas_item;

uniform float emissive;
uniform vec3 colour;
uniform sampler2D diffuse;

void fragment() 
{
	COLOR = texture(diffuse, UV);
}