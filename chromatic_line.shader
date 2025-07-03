
shader_type canvas_item;

uniform sampler2D gradient_tex : hint_default_white;
uniform float offset = 0.01;
uniform float speed = 2.0;

void fragment() {
    float t = TIME * speed;
    vec2 shift = vec2(sin(t), cos(t)) * offset;

    vec4 tex_r = texture(gradient_tex, UV + shift);
    vec4 tex_g = texture(gradient_tex, UV);
    vec4 tex_b = texture(gradient_tex, UV - shift);

    vec3 color = vec3(tex_r.r, tex_g.g, tex_b.b);

    if (color == vec3(0.0)) {
        color = vec3(1.0, 1.0, 1.0);
    }

    COLOR = vec4(color, 1.0);
}
