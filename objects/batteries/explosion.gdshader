shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float explosion_progress : hint_range(0.0, 1.2) = 0.0;
uniform float burn_amount : hint_range(0.0, 1.0) = 0.0;

uniform sampler2D noise_texture : filter_nearest;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.12;

uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.5, 1.0);  // Núcleo amarillo brillante
uniform vec4 edge_color : source_color = vec4(1.0, 0.35, 0.05, 1.0); // Borde naranja fuego
uniform vec4 burn_color : source_color = vec4(0.2, 0.15, 0.15, 1.0); // Tinte quemado/ceniza

uniform float wave_width : hint_range(0.05, 0.5) = 0.25;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	if (tex_color.a < 0.01) {
		discard;
	}

	// Distancia radial desde el centro del sprite
	float dist = distance(UV, vec2(0.5)) / 0.707;
	float noise_val = texture(noise_texture, UV).r;
	float noisy_dist = dist + (noise_val - 0.5) * noise_strength;

	// Onda de fuego expansiva (sin eliminar la imagen)
	if (explosion_progress > 0.0 && explosion_progress <= 1.2) {
		float diff = abs(noisy_dist - explosion_progress);
		
		if (diff < wave_width) {
			float intensity = 1.0 - (diff / wave_width);
			intensity = smoothstep(0.0, 1.0, intensity);
			
			vec3 flame = mix(edge_color.rgb, core_color.rgb, intensity);
			tex_color.rgb = mix(tex_color.rgb, flame, intensity * 0.95);
		}
	}

	// Aspecto quemado / desactivado posterior
	if (burn_amount > 0.0) {
		vec3 charred = mix(tex_color.rgb * 0.35, burn_color.rgb, 0.4);
		tex_color.rgb = mix(tex_color.rgb, charred, burn_amount);
	}

	// Destello de impacto inicial
	tex_color.rgb = mix(tex_color.rgb, vec3(1.0), flash_amount);

	COLOR = tex_color;
}
