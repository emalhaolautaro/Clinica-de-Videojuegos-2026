shader_type canvas_item;

// Flash blanco: 0.0 = color original, 1.0 = completamente blanco
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

// Fade out: 0.0 = visible, 1.0 = invisible
uniform float fade_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    // Flash: mezcla el color del píxel con blanco
    tex_color.rgb = mix(tex_color.rgb, vec3(1.0), flash_amount);
    // Fade: reduce la opacidad
    tex_color.a *= (1.0 - fade_amount);
    COLOR = tex_color;
}
