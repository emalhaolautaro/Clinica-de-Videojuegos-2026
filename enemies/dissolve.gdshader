shader_type canvas_item;

// Controla el progreso de la disolución: 0.0 = visible, 1.0 = invisible
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;

// Textura de ruido para el patrón de disolución
uniform sampler2D noise_texture : filter_nearest;

// Color del borde de disolución
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);

// Ancho del borde brillante
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float noise_value = texture(noise_texture, UV).r;

	// Si el valor de ruido es menor que dissolve_amount, el píxel desaparece
	if (noise_value < dissolve_amount) {
		discard;
	}

	// Borde brillante: píxeles que están cerca de desaparecer
	if (noise_value < dissolve_amount + edge_width) {
		float edge_intensity = 1.0 - (noise_value - dissolve_amount) / edge_width;
		tex_color.rgb = mix(tex_color.rgb, edge_color.rgb, edge_intensity);
	}

	COLOR = tex_color;
}
