// "The Hypnotic Contract" - V2 with enhanced VHS effects.
shader_type canvas_item;

// --- Thematic Color Palette ---
uniform vec4 temptation_red : source_color = vec4(0.8, 0.0, 0.1, 1.0);
uniform vec4 corruption_purple : source_color = vec4(0.5, 0.0, 0.9, 1.0);
uniform vec4 obsidian_black : source_color = vec4(0.08, 0.05, 0.09, 1.0);

// --- Swirl Controls ---
uniform float spin_speed : hint_range(0.0, 5.0) = 1.0;
uniform float move_speed : hint_range(0.0, 10.0) = 4.0;
uniform float contrast : hint_range(1.0, 10.0) = 4.5;
uniform float zoom : hint_range(10.0, 50.0) = 30.0;
uniform float pixel_filter : hint_range(100.0, 1500.0) = 740.0;

// --- VHS & Corruption Effects (Defaults increased for visibility) ---
uniform float chromatic_aberration : hint_range(0.0, 0.05) = 0.01;
uniform float noise_amount : hint_range(0.0, 0.5) = 0.1;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float screen_jitter : hint_range(0.0, 0.1) = 0.005;
uniform float vignette_darkness : hint_range(0.0, 2.0) = 1.2;

// --- System Uniforms ---
uniform vec2 screen_size;

// Helper function for pseudo-random noise
float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// The core function that generates the swirling colors (unchanged)
vec3 generate_swirl(vec2 coords) {
    highp float pixel_size = length(screen_size.xy) / pixel_filter;
    highp vec2 uv = (floor(coords.xy * (1.0 / pixel_size)) * pixel_size - 0.5 * screen_size.xy) / length(screen_size.xy);
    
    highp float speed = TIME * (spin_speed * 0.2) + 302.2;
    highp float new_pixel_angle = atan(uv.y, uv.x) + speed;
    highp float uv_len = length(uv);
    uv = vec2(uv_len * cos(new_pixel_angle), uv_len * sin(new_pixel_angle));

    uv *= zoom;
    speed = TIME * move_speed;
    highp vec2 uv2 = vec2(uv.x + uv.y);

    for(int i = 0; i < 5; i++) {
        uv2 += sin(max(uv.x, uv.y)) + uv;
        uv  += 0.5 * vec2(cos(5.1123 + 0.353 * uv2.y + speed * 0.1311), sin(uv2.x - 0.113 * speed));
        uv  -= 1.0 * cos(uv.x + uv.y) - 1.0 * sin(uv.x * 0.711 - uv.y);
    }

    highp float paint_res = min(2.0, max(0.0, length(uv) * 0.035 * contrast));
    highp float c1p = max(0.0, 1.0 - contrast * abs(1.0 - paint_res));
    highp float c2p = max(0.0, 1.0 - contrast * abs(paint_res));
    highp float c3p = 1.0 - min(1.0, c1p + c2p);

    return temptation_red.rgb * c1p + corruption_purple.rgb * c2p + obsidian_black.rgb * c3p;
}

void fragment() {
    // --- 1. Calculate Jitter and Aberration Offsets ---
	// We calculate the offsets first before generating the main pattern.
    float jitter_offset = (rand(vec2(TIME * 0.1, 0.0)) - 0.5) * screen_jitter * screen_size.x;
    float aberration_offset = chromatic_aberration * 50.0; // Scaled for better visibility

    // --- 2. Generate Color with Chromatic Aberration ---
	// We pass the calculated jitter and aberration offsets into the swirl generator.
    vec3 col_r = generate_swirl(FRAGCOORD.xy + vec2(aberration_offset + jitter_offset, 0.0));
    vec3 col_g = generate_swirl(FRAGCOORD.xy + vec2(jitter_offset, 0.0));
    vec3 col_b = generate_swirl(FRAGCOORD.xy - vec2(aberration_offset - jitter_offset, 0.0));
    vec3 final_color = vec3(col_r.r, col_g.g, col_b.b);

    // --- 3. Apply Scanlines (NEW, more effective method) ---
	// Using mod() creates sharp, repeating lines.
	// `mod(FRAGCOORD.y, 3.0)` creates a line every 3 pixels.
	// `step(2.0, ...)` makes the line 1 pixel thick.
    float scanline_value = step(2.0, mod(FRAGCOORD.y, 3.0));
	// We mix the original color with a darkened version based on the scanline value.
    final_color = mix(final_color * (1.0 - scanline_intensity), final_color, scanline_value);

    // --- 4. Apply Noise ---
    float noise = (rand(UV) - 0.5) * noise_amount;
    final_color += noise;

    // --- 5. Apply Vignette ---
    float vignette = 1.0 - (vignette_darkness * length(UV - 0.5));
    final_color *= vignette;
	
	// Clamp the final color to prevent weird brightness artifacts from effects adding up.
    final_color = clamp(final_color, 0.0, 1.0);

    // --- Final Output ---
    COLOR = vec4(final_color, 1.0);
}