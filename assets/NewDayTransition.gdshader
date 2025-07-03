shader_type canvas_item;

uniform float time : hint_time;
uniform float scanline_strength = 0.1;
uniform float distortion_strength = 0.005;
uniform float chroma_offset = 1.5;

void fragment() {
    vec2 uv = UV;

    // Vertical distortion wave
    float wave = sin(uv.y * 40.0 + time * 10.0) * distortion_strength;
    uv.x += wave;

    // RGB chromatic aberration
    vec4 r = texture(TEXTURE, uv + vec2(chroma_offset / VIEWPORT_SIZE.x, 0.0));
    vec4 g = texture(TEXTURE, uv);
    vec4 b = texture(TEXTURE, uv - vec2(chroma_offset / VIEWPORT_SIZE.x, 0.0));

    vec4 color = vec4(r.r, g.g, b.b, 1.0);

    // Horizontal scanlines
    float scanline = sin(uv.y * VIEWPORT_SIZE.y * 1.5) * scanline_strength;
    color.rgb -= scanline;

    COLOR = color;
}