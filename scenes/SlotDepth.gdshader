shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform sampler2D overlay_texture;

uniform float intensity : hint_range(0.0, 1.0) = 0.3;
uniform float zoom : hint_range(0.5, 2.0) = 1.0;
uniform float repeat_strength : hint_range(0.0, 10.0) = 2.0;
uniform float aberration_strength : hint_range(0.0, 0.01) = 0.003;
uniform float ripple_speed = 1.0;
uniform float ripple_strength = 0.05;
uniform float border_softness = 5.0;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Centered screen space (-1 to +1)
    vec2 centered = (uv - 0.5) * zoom * 2.0;
    float r = length(centered);

    // Ripple distortion
    float ripple = sin((r + TIME * ripple_speed) * 10.0) * ripple_strength;
    centered += centered * ripple;

    // Lens bulge distortion
    float distortion = 1.0 + intensity * pow(r, 2.0);
    vec2 distorted = centered / distortion;

	// Signed fold: reflect repeatedly toward center
	distorted = mod(distorted * repeat_strength + 1.0, 2.0) - 1.0;
	distorted = abs(distorted);

    // RGB chromatic aberration offsets
    vec4 col;
    col.r = texture(SCREEN_TEXTURE, distorted + aberration_strength).r;
    col.g = texture(SCREEN_TEXTURE, distorted).g;
    col.b = texture(SCREEN_TEXTURE, distorted - aberration_strength).b;
    col.a = 1.0;

    // Circular soft mask (radial vignette)
    float mask = smoothstep(1.0, 1.0 - 1.0 / border_softness, r);

    // Optional highlight overlay
    vec4 overlay = texture(overlay_texture, uv);
    col.rgb += overlay.rgb * overlay.a;

    // Blend with alpha mask
    COLOR = col * (1.0 - mask);
}
