shader_type spatial;

uniform float speed = 1.0;

void vertex() {
	VERTEX.y += sin(VERTEX.x + TIME * speed);
	VERTEX.y += sin(VERTEX.z + TIME * speed);

}
