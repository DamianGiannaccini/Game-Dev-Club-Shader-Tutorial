shader_type spatial;

//Used for changing the default colors
uniform vec3 albedo: source_color;
uniform float metallic: hint_range(0.0, 1.0) = 0;
uniform float roughness: hint_range(0.0, 1.0) = 0.02;

//Noise functions layered over top each other to look like waves
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;

//Variables for animating the water
uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);
uniform float time_scale: hint_range(0.0, 0.2, 0.005) = 0.025;

//Fresnel (Water light effect)
uniform vec3 albedo_fresnel: source_color;

//Changing heights of vertexs
uniform sampler2D wave;
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;

//Varying variables to scale the mesh
varying float height;
varying vec3 world_pos;

//Color change based on depth
uniform vec4 color_deep: source_color;
uniform vec4 color_shallow: source_color;
uniform float beers_law = 2.0;
uniform float depth_offset = -0.75;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

//Edge foam
uniform float edge_scale = 0.1;
uniform float near = 1.0;
uniform float far = 100.0;
uniform vec3 edge_color: source_color;

//Calculates the edges
float edge(float depth){
	depth = 1.0 - 2.0 * depth;
	return near * far / (far + depth * (near - far));
}

//Calculates fresnel
float fresnel(float amount, vec3 normal, vec3 view){
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
	//Sets height for each vertex
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_pos.xz / noise_scale + TIME * time_scale).r;
	VERTEX.y += height * height_scale;
}

void fragment() {
	//Depth calculations (No idea why it works just random youtube comment
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_texture);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float depth_blend = exp((-view.z + VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);
	
	//Calculate color change based on depth
	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);
	
	//Edge foam
	float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = edge(FRAGCOORD.z);
	float z_dif = z_depth - z_pos;
	vec3 depth_color_adj = mix(edge_color, color, step(edge_scale, z_dif));
	
	
	//Time calculations for the wave normal map movement
	vec2 time = (TIME * wave_direction) * time_scale;
	vec2 time2 = (TIME * wave_direction2) * time_scale;
	
	//Mixes the 2 noise functions
	vec3 normal_blend = mix(texture(texture_normal, world_pos.xz + time).rgb, texture(texture_normal2, world_pos.xz + time2).rgb, 0.5);
	
	//Calculates fresnel and sets accordingly
	float fresnel = fresnel(5.0, NORMAL, VIEW);
	vec3 surface_color = mix(albedo, albedo_fresnel, fresnel);
	

	//Sets all values
	ALBEDO = clamp(surface_color + depth_color_adj, vec3(0.0), vec3(1.0));
	//Abledo with depth before edge: ALBEDO = mix(surface_color, color, 0.75);
	ROUGHNESS = roughness;
	METALLIC = metallic;
	NORMAL_MAP = normal_blend;
}

