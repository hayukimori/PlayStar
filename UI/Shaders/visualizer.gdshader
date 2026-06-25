shader_type canvas_item;

uniform vec4 bar_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); 
uniform float corner_radius : hint_range(0.0, 1.0) = 0.5; 

void fragment() {
    vec2 uv = UV;
    
    uv.y -= 0.5;
    
    float num_bars = 5.0;
    float bar_width = 0.15;
    float gap = (1.0 - (num_bars * bar_width)) / (num_bars + 1.0);
    
    float bar_index = floor((uv.x - gap) / (bar_width + gap));
    
    float local_x = mod(uv.x - gap, bar_width + gap);
    
    vec4 final_color = vec4(0.0);
    
    if (bar_index >= 0.0 && bar_index < num_bars && local_x < bar_width) {     
        float anim_speed = 7.0;
        float offset = bar_index * 2.1;
        
        float height_factor;
        if (bar_index == 0.0) height_factor = 0.6 + 0.3 * sin(TIME * anim_speed + offset);
        else if (bar_index == 1.0) height_factor = 0.7 + 0.2 * cos(TIME * anim_speed * 1.3 + offset);
        else height_factor = 0.5 + 0.2 * sin(TIME * anim_speed * 0.9 + offset);

        float max_y_offset = height_factor / 4.0;

        // --- Rounded corners ---
        float center_x = bar_width / 2.0;
        
        // Distance to center
        vec2 dist_to_center = vec2(
            abs(local_x - center_x) / center_x, // 0.0 center X, 1.0 border X
            abs(uv.y) / max_y_offset            // 0.0 center Y, 1.0 anim height border
        );
        
        float corner_softness = 0.02;
        
        float aspect_corrected_radius = corner_radius * (bar_width / 0.5);
        

        float v = length(max(dist_to_center - (1.0 - aspect_corrected_radius), 0.0)) - aspect_corrected_radius;
        float d = smoothstep(corner_softness, 0.0, v);
        
        // Color

        if (abs(uv.y) < max_y_offset) {
             final_color = vec4(bar_color.rgb, d * bar_color.a);
        }
    }
    
    COLOR = final_color;
}