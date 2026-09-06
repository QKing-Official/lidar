shader_type canvas_item;

uniform float dither_strength : hint_range(0.0, 1.0) = 0.25;
uniform float pixel_size : hint_range(1.0, 8.0) = 2.0;
uniform float jitter : hint_range(0.0, 1.0) = 0.15;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 4x4 Bayer dithering pattern.
// Returns values from 0.0 to 15.0.
float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));

	if (y == 0) {
		if (x == 0) return 0.0;
		if (x == 1) return 8.0;
		if (x == 2) return 2.0;
		return 10.0;
	}

	if (y == 1) {
		if (x == 0) return 12.0;
		if (x == 1) return 4.0;
		if (x == 2) return 14.0;
		return 6.0;
	}

	if (y == 2) {
		if (x == 0) return 3.0;
		if (x == 1) return 11.0;
		if (x == 2) return 1.0;
		return 9.0;
	}

	if (x == 0) return 15.0;
	if (x == 1) return 7.0;
	if (x == 2) return 13.0;
	return 5.0;
}

void fragment() {

	// Screen resolution.
	vec2 screen_size = 1.0 / TEXTURE_PIXEL_SIZE;

	// PSX-style chunky pixel grid.
	vec2 pixel_pos = floor(UV * screen_size / pixel_size);

	vec2 pixel_uv =
		(pixel_pos + 0.5) *
		pixel_size /
		screen_size;

	// Original color.
	vec4 original = texture(TEXTURE, pixel_uv);

	// Calculate brightness WITHOUT changing the color.
	float luminance = dot(
		original.rgb,
		vec3(0.299, 0.587, 0.114)
	);

	// Bayer threshold.
	float threshold = bayer4(pixel_pos) / 16.0;

	// Very subtle temporal crawling.
	float noise =
		(hash(pixel_pos + floor(TIME * 8.0)) - 0.5)
		* jitter;

	threshold += noise;

	// Dither mask.
	float dither =
		step(threshold, luminance);

	/*
		IMPORTANT:

		We don't quantize RGB.

		The original RGB is preserved.
		The dither only determines whether
		the pixel gets partially suppressed.
	*/
	float darkness =
		1.0 - dither_strength * (1.0 - dither);

	vec3 final_color =
		original.rgb * darkness;

	COLOR = vec4(final_color, original.a);
}