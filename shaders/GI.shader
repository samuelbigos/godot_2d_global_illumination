shader_type canvas_item;

// uniforms
uniform vec2 LIGHT_POS = vec2(0.0, 0.0);

// consts
uniform float PI = 3.141596;
uniform float RAYS_PER_PIXEL = 32.0;
uniform vec2 RESOLUTION = vec2(0.0, 0.0);

uniform sampler2D in_data;
uniform sampler2D last_frame_buffer;
uniform sampler2D noise_texture;
uniform int frame = 0;

float epsilon()
{
	return 0.5/RESOLUTION.x;
}

float sd_box(vec2 p, vec2 b)
{
	vec2 d = abs(p) - b;
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sd_sphere(vec2 p, float s)
{
	return length(p)-s;
}

highp float box1(vec2 uv) { return sd_box(uv - vec2(1.2,0), vec2(0.05,0.4)); }
highp float box2(vec2 uv) { return sd_box(uv - vec2(0.,0.4), vec2(0.9,0.05)); }
highp float box3(vec2 uv) { return sd_box(uv - vec2(0.,-0.5), vec2(1.2,0.03)); }
highp float box4(vec2 uv) { return sd_sphere(uv - vec2(-0.9,-0.1), 0.1); }
highp float box5(vec2 uv) { return sd_box(uv - vec2(1.75,-0.3), vec2(0.05,1.3)); }
highp float box6(vec2 uv) { return sd_box(uv - vec2(0,1), vec2(1.7,0.05)); }
highp float box7(vec2 uv) { return sd_box(uv - vec2(0,-1), vec2(1.7,0.05)); }
highp float box8(vec2 uv) { return sd_box(uv - vec2(-1.75,-0.3), vec2(0.05,1.3)); }
highp float light_dist(vec2 uv) { return sd_sphere(LIGHT_POS + uv, 0.05); }

int get_material(vec2 uv)
{
    float test = epsilon();
	vec2 st = uv;
    st.x *= RESOLUTION.y / RESOLUTION.x;
	if(box1(uv) < test) return 0;
	else if(box2(uv) < test) return 1;
	else if(box3(uv) < test) return 2;
	else if(box4(uv) < test) return 3;
	else if(light_dist(uv) < test) return 4;
	else if(box5(uv) < test) return 5;
	else if(box6(uv) < test) return 6;
	else if(box7(uv) < test) return 7;
	else if(box8(uv) < test) return 8;
    else return 9;
}

highp float map(vec2 uv)
{
	float d = box1(uv);
	d = min(d, box2(uv));
	d = min(d, box3(uv));
	d = min(d, box4(uv));
	d = min(d, box5(uv));
	d = min(d, box6(uv));
	d = min(d, box7(uv));
	d = min(d, box8(uv));
	d = min(d, light_dist(uv));
    return d;
}

bool raymarch(vec2 origin, vec2 ray, out vec2 hitPos, out float d)
{
	highp float t = 0.0;
	highp float dist;
	highp vec2 samplePoint;
	for(int i = 0; i < 32; i++)
	{
		samplePoint = origin + ray * t;
		dist = map(samplePoint);
		t += dist;
		d = t;
		if(dist < epsilon())
        {
            hitPos = samplePoint;
            return true;
        }
	}
	return false;
}

float get_emission_from_buffer(vec2 uv)
{
    vec2 pix = 1.0 / RESOLUTION.xy;
    float e = max(texture(last_frame_buffer, uv + pix * vec2(-1,1)).a,0.);
    e = max(max(texture(last_frame_buffer, uv + pix * vec2(0,1)).a,0.),e);
    e = max(max(texture(last_frame_buffer, uv + pix * vec2(1,1)).a,0.),e);
    e = max(max(texture(last_frame_buffer, uv + pix * vec2(-1,0)).a,0.),e);
    e = max(max(texture(last_frame_buffer, uv + pix * vec2(0,0)).a,0.),e);
    e = max(max(texture(last_frame_buffer, uv + pix * vec2(1,0)).a,0.),e);
    e = max(max(texture(last_frame_buffer, uv + pix * vec2(-1,-1)).a,0.),e);
    e = max(max(texture(last_frame_buffer, uv + pix * vec2(0,-1)).a,0.),e);
    e = max(max(texture(last_frame_buffer, uv + pix * vec2(1,-1)).a,0.),e);
    return e;
}

void fragment() 
{
	float surfaces_emission[10] = float[10] (
		0.0,
		0.0, 
		0.0, 
		0.0,
		2.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0
	);
	vec3 surfaces_colour[10] = vec3[10] (
		vec3(1.0, 1.0, 0.0), 
		vec3(1.0, 0.0, 0.0), 
		vec3(1.0, 0.0, 0.0), 
		vec3(1.0, 0.0, 1.0),
		vec3(1.0, 1.0, 1.0),
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, 0.0, 1.0),
		vec3(0.0, 1.0, 0.0),
		vec3(0.0, 1.0, 0.0),
		vec3(1.0, 1.0, 1.0)
	);
	
	vec2 uv = UV;	
	float aspect = RESOLUTION.x / RESOLUTION.y;
    float invAspect = RESOLUTION.y / RESOLUTION.x;
    uv.x *= aspect;
		
	vec3 col = vec3(0.0);
    float emis = 0.0;
	
	vec2 time = vec2(TIME * 0.923213456123, -TIME *0.99584367);
    float rand02pi = texture(noise_texture, fract((uv + time)*0.4)).r*2.*PI;//Noise sample
    float golden_angle = PI * (3. - sqrt(5.));
	
	for(float i = 0.0; i < RAYS_PER_PIXEL; i++)
    {
		highp vec2 hit_pos;
		highp float dist;
        highp float curAngle = rand02pi + golden_angle * i;
		highp vec2 rand_direction = vec2(cos(curAngle), sin(curAngle));
		bool hit = raymarch(uv, rand_direction, hit_pos, dist);
		if(hit)
        {
			int mat = get_material(hit_pos);
			float mat_emissive = surfaces_emission[mat];
			vec3 mat_colour = surfaces_colour[mat];
			float d = max(dist, 0.0);
			vec2 st = hit_pos;
            st.x *= invAspect;
			
			highp float last_emission = 0.0;
			if(mat_emissive <= epsilon())
            {
				last_emission = get_emission_from_buffer(st);
			}
			if(frame == 0 || d <= epsilon())
				last_emission = 0.0;
			
			float emission = mat_emissive + last_emission;
            float r = 2.;
            float att = pow(max(1.0 - (d*d)/(r*r),0.),2.);
            emis += emission * att;
            col += (mat_emissive + last_emission)*mat_colour*att;
		}
	}
	
	col *= (1.0 / RAYS_PER_PIXEL);
    emis *= (1.0 / RAYS_PER_PIXEL);
	
	COLOR = vec4(vec3(col), emis);
	
	/*
    highp vec3 old_col = texture(last_frame_buffer, UV).rgb;
	vec3 total = col;
	
	if (frame == 0) 
		old_col = vec3(0.0);
		
	float integ = 3.;
	COLOR = vec4( (1.-(1./integ))*old_col +total*(1./integ), emis);
	*/
}