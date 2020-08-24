shader_type canvas_item;

// uniforms
uniform float PI = 3.141596;
uniform vec2 resolution;
uniform float rays_per_pixel;
uniform sampler2D distance_data;
uniform sampler2D scene_data;
uniform sampler2D last_frame_data;
uniform sampler2D noise_data;
uniform float dist_mod;

float epsilon()
{
	return 0.5 / resolution.x;
}

void get_material(vec2 uv, vec4 hit_data, out float emissive, out vec3 colour)
{	
	if(hit_data.x / dist_mod < epsilon())
	{
		vec4 mat_data = texture(scene_data, uv);
		if(mat_data.x > 0.0 || mat_data.y > 0.0 || mat_data.z > 0.0)
			emissive = 1.0;
		else
			emissive = 0.0;
		
		emissive = mat_data.x * 4.0;
		colour = mat_data.xyz;
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

bool raymarch(vec2 origin, vec2 ray, out vec2 hitPos, out vec4 hit_data, out float d)
{
	float t = 0.0;
	float prev_dist = 1.0;
	float dist = 1.0;
	vec2 samplePoint;
	for(int i = 0; i < 32; i++)
	{
		samplePoint = origin + ray * t;
		dist = map(samplePoint, hit_data);
		if(dist < epsilon())
		{
			hitPos = samplePoint;
  			return true;
		}
		
		t += dist;
		d = t;
	}
	return false;
}

float get_emission_from_buffer(vec2 uv)
{
	vec2 pix = 1.0 / resolution.xy;
	float e = max(texture(last_frame_data, uv + pix * vec2(-1,1)).a,0.);
	e = max(max(texture(last_frame_data, uv + pix * vec2(0,1)).a,0.),e);
	e = max(max(texture(last_frame_data, uv + pix * vec2(1,1)).a,0.),e);
	e = max(max(texture(last_frame_data, uv + pix * vec2(-1,0)).a,0.),e);
	e = max(max(texture(last_frame_data, uv + pix * vec2(0,0)).a,0.),e);
	e = max(max(texture(last_frame_data, uv + pix * vec2(1,0)).a,0.),e);
	e = max(max(texture(last_frame_data, uv + pix * vec2(-1,-1)).a,0.),e);
	e = max(max(texture(last_frame_data, uv + pix * vec2(0,-1)).a,0.),e);
	e = max(max(texture(last_frame_data, uv + pix * vec2(1,-1)).a,0.),e);
	return 4.0;
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
		float dist;
		float cur_angle = rand02pi + golden_angle * i;
		vec2 rand_direction = vec2(cos(cur_angle), sin(cur_angle));
		bool hit = raymarch(uv, rand_direction, hit_pos, hit_data, dist);
		if(hit)
		{
			float mat_emissive;
			vec3 mat_colour;
			get_material(hit_pos, hit_data, mat_emissive, mat_colour);
			
			float d = max(dist, 0.0);
			vec2 st = hit_pos;
			st.x *= invAspect;
			
			highp float last_emission = 0.0;
			if(mat_emissive <= epsilon())
			{
				last_emission = get_emission_from_buffer(st);
			}
			//if(d <= epsilon())
			//	last_emission = 0.0;
			
			float emission = mat_emissive + last_emission;
			float r = 2.;
			float att = 1.0;//pow(max(1.0 - (d*d)/(r*r),0.),2.);
			emis += emission * att;
			col += (mat_emissive + last_emission) * mat_colour * att;
		}
	}
	
	col *= (1.0 / rays_per_pixel);
    emis *= (1.0 / rays_per_pixel);
	
	COLOR = vec4(vec3(1.0), emis);

	//COLOR = vec4(vec2(length(texture(in_data, uv).xy)), 0.0, 1.0);
	/*
    highp vec3 old_col = texture(last_frame_buffer, UV).rgb;
	vec3 total = col;
	
	if (frame == 0) 
		old_col = vec3(0.0);
		
	float integ = 3.;
	COLOR = vec4( (1.-(1./integ))*old_col +total*(1./integ), emis);
	*/
}