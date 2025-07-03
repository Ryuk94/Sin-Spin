shader_type canvas_item;

uniform float time;
uniform float scanline_strength = 0.1;
uniform float distortion_strength = 0.005;
uniform float chroma_offset = 1.5;

void fragment() {
    vec2 uv = UV;

    // Wavy distortion
    float wave = sin(uv.y * 40.0 + time * 10.0) * distortion_strength;
    uv.x += wave;

    // Chromatic aberration (RGB split)
    vec2 offset = vec2(chroma_offset) * TEXTURE_PIXEL_SIZE;
    vec4 r = texture(TEXTURE, uv + offset);
    vec4 g = texture(TEXTURE, uv);
    vec4 b = texture(TEXTURE, uv - offset);
    vec4 color = vec4(r.r, g.g, b.b, 1.0);

    // Scanlines
    float scanline = sin(uv.y * 800.0) * scanline_strength; // tweak 800 for line density
    color.rgb -= scanline;

    COLOR = color;
}