shader_type canvas_item;

uniform bool palette_swap_enabled = false;
uniform float match_threshold = 0.002;
uniform vec4 source_palette[14];
uniform vec4 target_palette[14];

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	if (palette_swap_enabled && texel.a > 0.0) {
		for (int i = 0; i < 14; i++) {
			vec3 delta = abs(texel.rgb - source_palette[i].rgb);
			if (delta.r <= match_threshold && delta.g <= match_threshold && delta.b <= match_threshold) {
				texel.rgb = target_palette[i].rgb;
				break;
			}
		}
	}

	COLOR = texel * COLOR;
}
