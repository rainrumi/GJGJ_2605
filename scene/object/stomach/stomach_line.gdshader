shader_type canvas_item;

uniform sampler2D line_texture : source_color, repeat_enable, filter_nearest;
uniform vec2 line_texture_size = vec2(6.0, 6.0);
uniform vec2 mesh_size = vec2(153.0, 10.0);
uniform float wave_amplitude = 1.0;
uniform float wave_frequency = 15.0;
uniform float edge_keep_width = 8.0;

varying vec2 world_position;


void vertex() {
	float is_top_edge = 1.0 - step(0.5, VERTEX.y);
	float left_keep = smoothstep(0.0, edge_keep_width, VERTEX.x);
	float right_keep = 1.0 - smoothstep(mesh_size.x - edge_keep_width, mesh_size.x, VERTEX.x);
	float edge_mask = left_keep * right_keep;
	VERTEX.y += sin((VERTEX.x / mesh_size.x) * TAU * wave_frequency + TIME) * wave_amplitude * is_top_edge * edge_mask;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
	vec4 mask_color = texture(TEXTURE, UV);
	vec2 texture_uv = world_position / line_texture_size;
	vec4 line_color = texture(line_texture, texture_uv);
	float mask_value = mask_color.a * max(max(mask_color.r, mask_color.g), mask_color.b);
	COLOR = vec4(line_color.rgb, line_color.a * mask_value) * COLOR;
}
