shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

uniform float explosion_progress : hint_range(0.0, 1.0) = 0.0;

uniform sampler2D noise_texture : filter_nearest;

uniform float noise_strength : hint_range(0.0, 0.5) = 0.15;

uniform vec4 edge_color : source_color = vec4(1.0, 0.6, 0.1, 1.0);

uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.4, 1.0);

uniform float edge_width : hint_range(0.01, 0.3) = 0.08;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	tex_color.rgb = mix(tex_color.rgb, vec3(1.0), flash_amount);

	// Distancia radial desde el centro del sprite
	float dist = distance(UV, vec2(0.5));
	// Normalizar para que las esquinas lleguen a ~1.0
	dist = dist / 0.707;

	// Muestrear ruido para bordes orgánicos
	float noise_val = texture(noise_texture, UV).r;
	float noisy_dist = dist + (noise_val - 0.5) * noise_strength;

	// El radio de la onda se expande con el progreso
	float wave_radius = explosion_progress;

	if (noisy_dist < wave_radius - edge_width) {
		discard;
	}

	if (noisy_dist < wave_radius) {
		float edge_factor = 1.0 - (wave_radius - noisy_dist) / edge_width;
		vec3 glow = mix(core_color.rgb, edge_color.rgb, edge_factor);
		tex_color.rgb = mix(glow, tex_color.rgb, edge_factor * 0.3);
		tex_color.a = max(tex_color.a, 1.0 - edge_factor * 0.5);
	}

	COLOR = tex_color;
}
