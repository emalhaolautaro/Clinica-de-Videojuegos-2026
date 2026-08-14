shader_type canvas_item;

// Progreso: 0.0 = normal, 1.0 = completamente pixelado y desvanecido
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Tamaño máximo de los "píxeles" al final del efecto
uniform float max_pixel_size : hint_range(1.0, 64.0) = 32.0;

void fragment() {
    // Calcular tamaño de píxel según el progreso
    float pixel_factor = mix(1.0, max_pixel_size, progress);
    float cells = 64.0 / pixel_factor;

    // Redondear las UV para crear el efecto pixelado
    vec2 pixel_uv = floor(UV * cells) / cells;

    vec4 tex_color = texture(TEXTURE, pixel_uv);

    // Fade out suave en la segunda mitad del efecto
    tex_color.a *= 1.0 - smoothstep(0.4, 1.0, progress);

    COLOR = tex_color;
}

