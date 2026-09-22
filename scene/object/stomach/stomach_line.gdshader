shader_type canvas_item;

uniform sampler2D line_texture : source_color, repeat_enable, filter_nearest;
uniform vec4 dot_color : source_color = vec4(0.94117647, 0.87843137, 1.0, 1.0);
uniform vec2 line_texture_size = vec2(6.0, 6.0);
uniform vec2 line_texture_group_count = vec2(6.0, 6.0);
uniform float hatch_period = 5.0;
uniform vec2 mesh_size = vec2(153.0, 10.0);
uniform float wave_amplitude = 1.0;
uniform float wave_frequency = 15.0;
uniform float edge_keep_width = 8.0;
uniform float mask_clip_threshold = 0.05;
uniform float top_edge_dot_period = 1.0;
uniform float top_edge_dot_width = 1.0;
uniform float top_edge_thickness = 1.0;

varying vec2 world_position;
varying vec2 world_origin;
varying vec2 world_scale;


float get_top_wave_y(float local_x, vec2 scale, float origin_x) {
	float scaled_x = local_x * scale.x;
	float left_keep = smoothstep(0.0, edge_keep_width, scaled_x);
	float right_keep = 1.0 - smoothstep(mesh_size.x * scale.x - edge_keep_width, mesh_size.x * scale.x, scaled_x);
	float edge_mask = left_keep * right_keep;
	float world_x = origin_x + scaled_x;
	float wave_phase = world_x * TAU * wave_frequency / mesh_size.x + TIME;
	return sin(wave_phase) * wave_amplitude / max(scale.y, 0.0001) * edge_mask;
}


float get_top_wave_pixel_y(float local_x, vec2 scale, float origin_x) {
	return ceil(get_top_wave_y(local_x, scale, origin_x));
}


float get_line_group_visibility(vec2 group_origin, vec2 group_size, vec2 scale, vec2 origin) {
	vec2 group_top_left = (group_origin - origin) / max(scale, vec2(0.0001));
	vec2 group_bottom_right = (group_origin + group_size - origin) / max(scale, vec2(0.0001));
	float left_x = clamp(group_top_left.x, 0.0, mesh_size.x);
	float right_x = clamp(group_bottom_right.x, 0.0, mesh_size.x);
	float quarter_x = mix(left_x, right_x, 0.25);
	float center_x = mix(left_x, right_x, 0.5);
	float three_quarter_x = mix(left_x, right_x, 0.75);
	float top_y = group_top_left.y;
	float max_wave_y = max(
		max(
			max(get_top_wave_y(left_x, scale, origin.x), get_top_wave_y(quarter_x, scale, origin.x)),
			get_top_wave_y(center_x, scale, origin.x)
		),
		max(get_top_wave_y(three_quarter_x, scale, origin.x), get_top_wave_y(right_x, scale, origin.x))
	);
	return 1.0 - step(top_y + 0.001, max_wave_y);
}


float get_top_edge_visibility(vec2 pixel_position, vec2 scale, vec2 origin) {
	float local_x = (pixel_position.x - origin.x) / max(scale.x, 0.0001);
	float local_y = (pixel_position.y - origin.y) / max(scale.y, 0.0001);
	float wave_y = get_top_wave_pixel_y(local_x, scale, origin.x);
	float pixel_y = floor(local_y + 0.5);
	float local_x_step = 1.0 / max(scale.x, 0.0001);
	float previous_wave_y = get_top_wave_pixel_y(local_x - local_x_step, scale, origin.x);
	float next_wave_y = get_top_wave_pixel_y(local_x + local_x_step, scale, origin.x);
	float current_dot = 1.0 - step(top_edge_thickness, abs(pixel_y - wave_y));
	float previous_dot = step(min(wave_y, previous_wave_y) - 0.001, pixel_y) * (1.0 - step(max(wave_y, previous_wave_y) + 0.001, pixel_y));
	float next_dot = step(min(wave_y, next_wave_y) - 0.001, pixel_y) * (1.0 - step(max(wave_y, next_wave_y) + 0.001, pixel_y));
	float edge_line = max(current_dot, max(previous_dot, next_dot));
	float dot_phase = mod(pixel_position.x - origin.x, top_edge_dot_period);
	float dot_line = 1.0 - step(top_edge_dot_width, dot_phase);
	float inside_mesh = step(0.0, local_x) * (1.0 - step(mesh_size.x, local_x));
	return edge_line * dot_line * inside_mesh;
}


float get_top_wave_clip(vec2 pixel_position, vec2 scale, vec2 origin) {
	float local_x = (pixel_position.x - origin.x) / max(scale.x, 0.0001);
	float local_y = (pixel_position.y - origin.y) / max(scale.y, 0.0001);
	float wave_y = get_top_wave_pixel_y(local_x, scale, origin.x);
	float pixel_y = floor(local_y + 0.5);
	return step(wave_y + top_edge_thickness, pixel_y);
}


void vertex() {
	vec2 scale = vec2(length(MODEL_MATRIX[0].xy), length(MODEL_MATRIX[1].xy));
	vec2 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	float is_top_edge = 1.0 - step(0.5, VERTEX.y);
	float wave_y = get_top_wave_y(VERTEX.x, scale, origin.x);
	VERTEX.y += wave_y * is_top_edge;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	world_origin = origin;
	world_scale = scale;
}


void fragment() {
	vec4 mask_color = texture(TEXTURE, UV);
	vec2 texture_uv = world_position / line_texture_size;
	vec2 texture_group_uv = floor(texture_uv * line_texture_group_count) / line_texture_group_count;
	vec2 group_origin = texture_group_uv * line_texture_size;
	vec2 group_size = line_texture_size / line_texture_group_count;
	float line_group_visibility = get_line_group_visibility(group_origin, group_size, world_scale, world_origin);
	vec2 pixel_uv = floor(world_position);
	float hatch_phase = mod(pixel_uv.x + pixel_uv.y, hatch_period);
	float hatch_value = 1.0 - step(1.0, hatch_phase);
	float raw_mask_value = mask_color.a * max(max(mask_color.r, mask_color.g), mask_color.b);
	float mask_value = smoothstep(mask_clip_threshold, mask_clip_threshold + 0.01, raw_mask_value);
	float top_edge_value = get_top_edge_visibility(floor(world_position), world_scale, world_origin);
	float top_wave_clip = get_top_wave_clip(floor(world_position), world_scale, world_origin);
	float hatch_value_masked = hatch_value * line_group_visibility * top_wave_clip * mask_value;
	float line_value = max(hatch_value_masked, top_edge_value);
	COLOR = vec4(dot_color.rgb, line_value * dot_color.a) * COLOR;
}
