shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int bands : hint_range(1, 8) = 3;
uniform float band_softness : hint_range(0.0, 1.0) = 0.05;
uniform vec4 shadow_color : source_color = vec4(0.2, 0.2, 0.3, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.3;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV);
	vec4 base_color = tex_color * tint * COLOR;
	ALBEDO = mix(base_color.rgb, vec3(1.0), flash_amount);
	ALPHA = base_color.a;
}

void light() {
	float NdotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float att = clamp(ATTENUATION, 0.0, 1.0);
	float intensity = NdotL * att;

	float b = max(float(bands), 1.0);
	float band_w = 1.0 / b;
	float idx = floor(intensity / band_w);
	float rem = (intensity - idx * band_w) / band_w;
	float half_soft = clamp(band_softness * 0.5, 0.001, 0.499);
	float factor = (idx + smoothstep(0.5 - half_soft, 0.5 + half_soft, rem)) / b;
	factor = clamp(factor, 0.0, 1.0);

	vec3 light_mult = mix(shadow_color.rgb, LIGHT_COLOR.rgb, factor);

	float NdotV = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - NdotV, 3.0) * factor * rim_strength;

	DIFFUSE_LIGHT += ALBEDO * light_mult + (rim * rim_color.rgb * LIGHT_COLOR.rgb);
}
