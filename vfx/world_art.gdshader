shader_type canvas_item;
render_mode unshaded;

global uniform bool art_grayscale;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 color = COLOR;
	color.rgb = mix(color.rgb, vec3(1.0), hit_flash);
	if (art_grayscale) {
		float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
		color.rgb = vec3(luminance);
	}
	COLOR = color;
}
