shader_type canvas_item;

uniform float radius : hint_range(0.0, 0.5) = 0.1;

void fragment() {
    vec2 uv = UV - 0.5;
    vec2 size = vec2(0.5) - vec2(radius);
    vec2 d = abs(uv) - size;
    float dist = length(max(d, 0.0)) - radius;
    float alpha = 1.0 - smoothstep(-0.002, 0.002, dist);
    COLOR = vec4(COLOR.rgb, COLOR.a * alpha);
}