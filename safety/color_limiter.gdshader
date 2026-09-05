shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

const vec3 C_BLACK = vec3(0.0, 0.0, 0.0);
const vec3 C_WHITE = vec3(1.0, 1.0, 1.0);
const vec3 C_RED   = vec3(1.0, 0.0, 0.0);

void fragment() {
    vec3 c = texture(screen_texture, SCREEN_UV).rgb;
    
    float d_black = distance(c, C_BLACK);
    float d_white = distance(c, C_WHITE);
    float d_red   = distance(c, C_RED);
    
    if (d_black <= d_white && d_black <= d_red) {
        COLOR = vec4(C_BLACK, 1.0);
    } else if (d_white <= d_red) {
        COLOR = vec4(C_WHITE, 1.0);
    } else {
        COLOR = vec4(C_RED, 1.0);
    }
}