shader_type canvas_item;

uniform sampler2D gradient_texture_1d : hint_default_white;
uniform float offset = 0.01;
uniform float speed = 2.0;

void fragment() {
	float t = TIME * speed;
	vec2 shift = vec2(sin(t), cos(t)) * offset;

	vec4 tex_r = texture(gradient_texture_1d, UV + shift);
	vec4 tex_g = texture(gradient_texture_1d, UV);
	vec4 tex_b = texture(gradient_texture_1d, UV - shift);

	COLOR.r = tex_r.r;
	COLOR.g = tex_g.g;
	COLOR.b = tex_b.b;
	COLOR.a = tex_g.a;
}
