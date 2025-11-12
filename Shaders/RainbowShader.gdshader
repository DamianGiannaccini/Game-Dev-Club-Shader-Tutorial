shader_type canvas_item;

uniform float speed = 1.0;

void fragment() {
	vec4 text = texture(TEXTURE, UV);
	
	float r = sin(TIME * speed) * 0.5 + 0.5;
	float g = sin(TIME * speed + 2.094) * 0.5 + 0.5;
	float b = sin(TIME * speed + 4.188) * 0.5 + 0.5;
	
	COLOR = vec4(r, g, b, text.a);
}

