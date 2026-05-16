shader_type canvas_item;

uniform sampler2D line_texture : source_color, repeat_enable, filter_nearest;
uniform vec2 line_texture_size = vec2(6.0, 6.0);
uniform vec2 mesh_size = vec2(153.0, 10.0);
uniform float wave_amplitude = 1.0;
uniform float wave_frequency = 15.0;
uniform float edge_keep_width = 8.0;
uniform float mask_clip_threshold = 0.05;

varying vec2 world_position;


void vertex() {
	vec2 scale = vec2(length(MODEL_MATRIX[0].xy), length(MODEL_MATRIX[1].xy));
	vec2 vertex_world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float is_top_edge = 1.0 - step(0.5, VERTEX.y);
	float world_x = VERTEX.x * scale.x;
	float left_keep = smoothstep(0.0, edge_keep_width, world_x);
	float right_keep = 1.0 - smoothstep(mesh_size.x * scale.x - edge_keep_width, mesh_size.x * scale.x, world_x);
	float edge_mask = left_keep * right_keep;
	float wave_phase = vertex_world_position.x * TAU * wave_frequency / mesh_size.x + TIME;
	VERTEX.y += sin(wave_phase) * wave_amplitude / max(scale.y, 0.0001) * is_top_edge * edge_mask;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
	vec4 mask_color = texture(TEXTURE, UV);
	vec2 texture_uv = world_position / line_texture_size;
	vec4 line_color = texture(line_texture, texture_uv);
	float raw_mask_value = mask_color.a * max(max(mask_color.r, mask_color.g), mask_color.b);
	float mask_value = smoothstep(mask_clip_threshold, mask_clip_threshold + 0.01, raw_mask_value);
	COLOR = vec4(line_color.rgb, line_color.a * mask_value) * COLOR;
}
