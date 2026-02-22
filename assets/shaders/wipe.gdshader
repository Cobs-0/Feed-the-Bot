shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Not used for now, but good to have

void fragment() {
    vec2 uv = UV;
    // Simple horizontal wipe from left to right
    // Only show texture where uv.x is less than progress
    if (uv.x < progress) {
        COLOR = texture(TEXTURE, UV);
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0); // Transparent where wiped
    }
}
