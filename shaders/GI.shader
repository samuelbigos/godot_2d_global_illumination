shader_type canvas_item;

// constants
uniform float PI = 3.141596;

// uniforms
uniform vec2 u_resolution = vec2(512.0, 512.0);
uniform float u_rays_per_pixel = 32;
uniform sampler2D u_distance_data;
uniform sampler2D u_scene_colour_data;
uniform sampler2D u_scene_emissive_data;
uniform sampler2D u_last_frame_data;
uniform sampler2D u_noise_data;
uniform float u_dist_mod = 10.0;
uniform bool u_bounce = true;
uniform bool u_denoise = true;
uniform float u_emission_multi = 1.0;
uniform float u_emission_range = 2.0;
uniform float u_emission_dropoff = 2.0;

float epsilon()
{
	return 0.5 / max(u_resolution.x, u_resolution.y);
}

void get_material(vec2 uv, vec4 hit_data, out float emissive, out vec3 colour)
{	
	if(hit_data.x / u_dist_mod < epsilon())
	{
		float inv_aspect = u_resolution.y / u_resolution.x;
		uv.x *= inv_aspect;
		vec4 emissive_data = texture(u_scene_emissive_data, uv);
		vec4 colour_data = texture(u_scene_colour_data, uv);
		emissive = emissive_data.r * u_emission_multi;
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
	float inv_aspect = u_resolution.y / u_resolution.x;
	uv.x *= inv_aspect;
	hit_data = texture(u_distance_data, uv);
	float d = hit_data.x / u_dist_mod;
    return d;
}

bool raymarch(vec2 origin, vec2 ray, out vec2 hit_pos, out vec4 hit_data, out float ray_dist)
{
	float t = 0.0;
	float prev_dist = 1.0;
	float step_dist = 1.0;
	vec2 sample_point;
	for(int i = 0; i < 64; i++)
	{
		sample_point = origin + ray * t;
		step_dist = map(sample_point, hit_data);
		if(step_dist < epsilon())
		{
			hit_pos = sample_point;
  			return true;
		}
		step_dist = max(step_dist, min(1.0 / u_resolution.x, 1.0 / u_resolution.y));
		t += step_dist;
		ray_dist = t;
	}
	return false;
}

void get_last_frame_data(vec2 uv, vec2 pix, out float last_emission, out vec3 last_colour)
{
	last_emission = 0.0;
	for(int x = -1; x <= 1; x++)
	{
		for(int y = -1; y <= 1; y++)
		{
			vec4 pixel = texture(u_last_frame_data, uv + pix * vec2(float(x), float(y)));
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
	float aspect = u_resolution.x / u_resolution.y;
	float inv_aspect = u_resolution.y / u_resolution.x;
	uv.x *= aspect;
		
	vec3 col = vec3(0.0);
	float emis = 0.0;
	
	vec2 time = vec2(TIME * 0.923213456123, -TIME *0.99584367);
	float rand02pi = texture(u_noise_data, fract((uv + time) * 0.4)).r * 2.0 * PI; // noise sample
	float golden_angle = PI * (3. - sqrt(5.));
	
	for(float i = 0.0; i < u_rays_per_pixel; i++)
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
			st.x *= inv_aspect;
			
			float last_emission = 0.0;
			vec3 last_colour = vec3(0.0);
			if(u_bounce)
			{
				if(mat_emissive < epsilon()) // This determines if emissive surfaces themselves can bounce light.
				{
					get_last_frame_data(st, SCREEN_PIXEL_SIZE, last_emission, last_colour);
				}
				if(ray_dist < epsilon()) // So light doesn't bounce off the surface it was emitted from.
					last_emission = 0.0;
			}
			
			float emission = mat_emissive + last_emission;
			float r = u_emission_range;
			float drop = u_emission_dropoff;
			float att = pow(max(1.0 - (ray_dist * ray_dist) / (r * r), 0.0), u_emission_dropoff);
			emis += emission * att;
			col += (mat_emissive + last_emission) * (mat_colour + last_colour) * att;
		}
	}
	
	emis *= (1.0 / u_rays_per_pixel);
	col *= (1.0 / u_rays_per_pixel);
	
	if(u_denoise)
	{
		vec4 last_9x9_average = vec4(0.0);
		vec2 pix = SCREEN_PIXEL_SIZE;
		for(int x = -1; x <= 1; x++)
		{
			for(int y = -1; y <= 1; y++)
			{ 
				vec2 st = uv;
				st.x *= inv_aspect;
				last_9x9_average += texture(u_last_frame_data, st + pix * vec2(float(x), float(y)));
			}
		}
		last_9x9_average = last_9x9_average / 9.0;
		float integ = 2.0;
		COLOR = vec4((1.0 - (1.0 / integ)) * last_9x9_average.rgb + col * (1.0 / integ), emis);
	}
	else
	{
		COLOR = vec4(col, emis);
	}
}