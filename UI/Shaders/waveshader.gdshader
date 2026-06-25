shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float amplitude = 8.0;
uniform float frequency = 20.0;
uniform float speed = 2.0;
uniform float thickness = 2.0;
uniform vec4 color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec2 uv = UV;
	
	
    if (uv.x > progress) {
        discard;
    }

    
    float wave = sin((uv.x * frequency) + TIME * speed) * amplitude;

    
    float center = 0.5 + wave / TEXTURE_PIXEL_SIZE.y;


    float dist = abs(uv.y - center);

    if (dist < thickness * TEXTURE_PIXEL_SIZE.y) {
        COLOR = color;
    } else {
        discard;
    }
}
