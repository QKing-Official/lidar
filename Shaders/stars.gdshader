shader_type canvas_item;

uniform float star_density : hint_range(1.0, 200.0) = 70.0;
uniform float star_threshold : hint_range(0.0, 1.0) = 0.94;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 0.4;  // much slower
uniform float cross_star_ratio : hint_range(0.9, 1.0) = 0.97;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 4-pointed polestar — sharp cross with bright core
float cross_star(vec2 p) {
    // p should be in [-1, 1] range
    float len = length(p);
    // Horizontal spike
    float hx = exp(-abs(p.y) * 25.0) * exp(-abs(p.x) * 2.5);
    // Vertical spike
    float hy = exp(-abs(p.x) * 25.0) * exp(-abs(p.y) * 2.5);
    // Bright core
    float core = exp(-len * 8.0);
    return clamp(hx + hy + core, 0.0, 1.0);
}

// Soft circular dot
float soft_dot(vec2 p, float size) {
    return exp(-dot(p, p) / (size * size));
}

void fragment() {
    vec2 uv = UV;
    
    // Very slow drift
    uv.y -= TIME * 0.008;
    uv.x += TIME * 0.004;
    
    // Grid cells
    vec2 grid = floor(uv * star_density);
    vec2 local = fract(uv * star_density); // [0,1] within cell
    vec2 centered = local - 0.5;           // [-0.5, 0.5] centered in cell
    
    float r  = random(grid);
    float r2 = random(grid + vec2(7.3, 4.1)); // second random for size variation
    
    // Reject cells below threshold
    float exists = step(star_threshold, r);
    
    // Each star has its own twinkle phase and speed
    float phase = r * 100.0 + TIME * twinkle_speed * (0.4 + r * 0.8);
    float twinkle = pow((sin(phase) + 1.0) / 2.0, 3.0);
    
    // Top ~3% of stars are 4-pointed cross stars, rest are soft dots
    float is_cross = step(cross_star_ratio, r);
    
    // Cross stars are large and obvious; dots are tiny pinpoints
    float cross_size = 0.30 + r2 * 0.12;  // bigger so spikes are clearly visible
    float dot_size   = 0.008 + r2 * 0.008; // tiny pinpoints
    
    // Branchless mixing using is_cross as a blend weight
    float cross_val = cross_star(centered / cross_size);
    float dot_val   = soft_dot(centered, dot_size);
    
    float shape = mix(dot_val, cross_val, is_cross);
    float intensity = exists * shape * twinkle;
    
    // Pure white stars on pure black void
    COLOR = vec4(vec3(intensity), 1.0);
}
