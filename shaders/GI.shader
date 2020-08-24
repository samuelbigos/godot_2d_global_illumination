shader_type canvas_item;

// uniforms
uniform float PI = 3.141596;
uniform vec2 resolution;
uniform float rays_per_pixel;
uniform sampler2D distance_data;
uniform sampler2D scene_colour_data;
uniform sampler2D scene_emissive_data;
uniform sampler2D last_frame_data;
uniform sampler2D noise_data;
uniform float dist_mod;
uniform bool do_bounce = true;
uniform bool do_denoise = true;

float epsilon()
{
	return 0.5 / resolution.x;
}

void get_material(vec2 uv, vec4 hit_data, out float emissive, out vec3 colour)
{	
	if(hit_data.x / dist_mod < epsilon())
	{
		vec4 emissive_data = texture(scene_emissive_data, uv);
		vec4 colour_data = texture(scene_colour_data, uv);
		emissive = emissive_data.r * 1.0;
		colour = colour_data.rgb;
	}
	else
	{
		emissive = 0.0;
		colour = vec3(0.0);
	}
}

float map(vec2 uv, out vec4 hit_data)
{
	hit_data = texture(distance_data, uv);
	float d = hit_data.x / dist_mod;
    return d;
}

bool raymarch(vec2 origin, vec2 ray, out vec2 hit_pos, out vec4 hit_data, out float ray_dist)
{
	float t = 0.0;
	float prev_dist = 1.0;
	float step_dist = 1.0;
	vec2 samplePoint;
	for(int i = 0; i < 32; i++)
	{
		samplePoint = origin + ray * t;
		step_dist = map(samplePoint, hit_data);
		if(step_dist < epsilon())
		{
			hit_pos = samplePoint;
  			return true;
		}
		
		t += step_dist;
		ray_dist = t;
	}
	return false;
}

void get_last_frame_data(vec2 uv, out float last_emission, out vec3 last_colour)
{
	last_emission = 0.0;
	vec2 pix = 1.0 / resolution.xy;
	for(int x = -1; x <= 1; x++)
	{
		for(int y = -1; y <= 1; y++)
		{
			vec4 pixel = texture(last_frame_data, uv + pix * vec2(float(x), float(y)));
			if(pixel.a > last_emission)
			{
				last_emission = pixel.a;
				last_colour = pixel.rgb;
			}
		}
	}
}

void fragment() 
{
	vec2 uv = UV;
	float aspect = resolution.x / resolution.y;
	float invAspect = resolution.y / resolution.x;
	uv.x *= aspect;
		
	vec3 col = vec3(0.0);
	float emis = 0.0;
	
	vec2 time = vec2(TIME * 0.923213456123, -TIME *0.99584367);
	float rand02pi = texture(noise_data, fract((uv + time)*0.4)).r*2.*PI;//Noise sample
	float golden_angle = PI * (3. - sqrt(5.));
	
	for(float i = 0.0; i < rays_per_pixel; i++)
	{
		vec2 hit_pos;
		vec4 hit_data;
		float ray_dist;
		float cur_angle = rand02pi + golden_angle * i;
		vec2 rand_direction = vec2(cos(cur_angle), sin(cur_angle));
		bool hit = raymarch(uv, rand_direction, hit_pos, hit_data, ray_dist);
		if(hit)
		{
			float mat_emissive;
			vec3 mat_colour;
			get_material(hit_pos, hit_data, mat_emissive, mat_colour);
			
			vec2 st = hit_pos;
			st.x *= invAspect;
			
			float last_emission = 0.0;
			vec3 last_colour = vec3(0.0);
			if(mat_emissive < epsilon()) // This determines if emissive surfaces themselves can bounce light.
			{
				if(do_bounce)
					get_last_frame_data(st, last_emission, last_colour);
			}
			if(ray_dist < epsilon()) // So light doesn't bounce off the surface it was emitted from.
				last_emission = 0.0;
			
			float emission = mat_emissive + last_emission;
			float r = 2.;
			float att = pow(max(1.0 - (ray_dist*ray_dist)/(r*r),0.),2.);
			emis += emission * att;
			col += (mat_emissive + last_emission) * (mat_colour + last_colour) * att;
		}
	}
	
	emis *= (1.0 / rays_per_pixel);
	col *= (1.0 / rays_per_pixel);

    vec4 old_frame = texture(last_frame_data, UV).rgba;
	float integ = 3.0;
	if(!do_denoise)
		integ = 1.0;
		
	COLOR = vec4((1.0 - (1.0 / integ)) * old_frame.rgb + col * (1.0 / integ), emis);
}