shader_type canvas_item;

uniform vec4 dot_color : source_color = vec4(0.94117647, 0.87843137, 1.0, 1.0);
uniform vec2 mesh_size = vec2(153.0, 10.0);
uniform float hatch_period = 5.0;
uniform float wave_amplitude = 1.0;
uniform float wave_frequency = 15.0;
uniform float wave_speed = 1.0;
uniform float wave_base_y = 2.0;
uniform float wave_edge_fade_width = 8.0;
uniform float top_edge_thickness = 1.0;
uniform float mask_clip_threshold = 0.05;


float get_wave_edge_mask(float local_x) {
	float left_mask = smoothstep(0.0, wave_edge_fade_width, local_x);
	float right_mask = 1.0 - smoothstep(mesh_size.x - wave_edge_fade_width, mesh_size.x, local_x);
	return left_mask * right_mask;
}


float get_wave_y(float local_x) {
	float edge_mask = get_wave_edge_mask(local_x);
	float phase = local_x / mesh_size.x * TAU * wave_frequency + TIME * wave_speed;
	return wave_base_y + sin(phase) * wave_amplitude * edge_mask;
}


void fragment() {
	vec2 local_pos = UV * mesh_size;
	vec2 pixel_pos = floor(local_pos);
	vec2 pixel_center = pixel_pos + vec2(0.5);
	vec4 mask_color = texture(TEXTURE, UV);

	float wave_y = get_wave_y(pixel_center.x);
	float inside_wave = step(wave_y, pixel_center.y);
	float distance_to_wave = abs(pixel_center.y - wave_y);
	float top_edge = 1.0 - step(top_edge_thickness * 0.5, distance_to_wave);

	float hatch_phase = mod(pixel_pos.x + pixel_pos.y, hatch_period);
	float hatch_value = 1.0 - step(1.0, hatch_phase);

	float raw_mask_value = mask_color.a;
	float mask_value = step(mask_clip_threshold, raw_mask_value);
	float hatch_value_masked = hatch_value * inside_wave * mask_value;
	float line_value = max(hatch_value_masked, top_edge);
	COLOR = vec4(dot_color.rgb, line_value * dot_color.a) * COLOR;
}
