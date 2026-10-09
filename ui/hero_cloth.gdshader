shader_type canvas_item;
uniform float motion = 1.0;
uniform float pulse = 0.0;
void fragment() {
	vec2 uv=UV;
	float cloth=smoothstep(0.38,0.92,uv.y);
	uv.x+=sin(TIME*2.4+uv.y*7.0)*0.0035*cloth*motion;
	vec4 art=texture(TEXTURE,uv);
	art.rgb+=vec3(0.03,0.045,0.05)*pulse;
	COLOR=art*COLOR;
}
