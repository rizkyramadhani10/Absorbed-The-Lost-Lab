shader_type canvas_item;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    // Hitung jarak dari pinggir kiri dan kanan (0.0 sampai 1.0)
    float fade_left = smoothstep(0.0, 0.2, UV.x);
    float fade_right = smoothstep(1.0, 0.8, UV.x);
    
    // Gabungkan fade ke alpha gambar
    color.a *= fade_left * fade_right;
    
    COLOR = color;
}