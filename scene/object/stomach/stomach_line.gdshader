shader_type canvas_item;

uniform sampler2D line_texture : source_color, repeat_enable, filter_nearest;
uniform vec2 line_texture_size = vec2(6.0, 6.0);

varying vec2 local_position;


void vertex() {
	local_position = VERTEX;
}


void fragment() {
	vec4 mask_color = texture(TEXTURE, UV);
	vec2 texture_uv = local_position / line_texture_size;
	vec4 line_color = texture(line_texture, texture_uv);
	float mask_value = mask_color.a * max(max(mask_color.r, mask_color.g), mask_color.b);
	COLOR = vec4(line_color.rgb, line_color.a * mask_value) * COLOR;
}
