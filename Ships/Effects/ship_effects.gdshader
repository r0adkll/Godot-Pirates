shader_type canvas_item;

// Combined ship effects. This material lives permanently on BoatSprite:
//  - `flash_active` is toggled by the hit_flash/sinking animations.
//  - `dutchman_strength` is tweened 0.0 -> 1.0 by gameplay code to fade
//    the ghostly "Dutchman" mode in and out.

uniform bool flash_active = false;

uniform float dutchman_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ghost_color : source_color = vec4(0.35, 0.65, 0.45, 1.0);
uniform vec4 glow_color : source_color = vec4(0.45, 0.95, 0.6, 1.0);
uniform float glow_width : hint_range(0.0, 8.0) = 2.0;
uniform float glow_intensity : hint_range(0.0, 8.0) = 1.2;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float ghost_alpha : hint_range(0.0, 1.0) = 0.85;
// Halo painted by the shader around the hull, in texture pixels.
// vertex() grows the sprite quad by this margin so the halo can draw
// outside the texture rect.
uniform float halo_size : hint_range(0.0, 48.0) = 16.0;
uniform float halo_strength : hint_range(0.0, 1.0) = 0.55;

// The vertex color carries the CanvasItem's modulate; writing COLOR from
// scratch in fragment() would otherwise discard it and break modulate
// fades (e.g. the sinking animation).
varying vec4 v_modulate;

const vec2 DIRS[8] = vec2[8](
	vec2(1.0, 0.0), vec2(0.70710678, 0.70710678),
	vec2(0.0, 1.0), vec2(-0.70710678, 0.70710678),
	vec2(-1.0, 0.0), vec2(-0.70710678, -0.70710678),
	vec2(0.0, -1.0), vec2(0.70710678, -0.70710678)
);

void vertex() {
	v_modulate = COLOR;
	// Grow the quad so the halo has room to render outside the sprite.
	vec2 margin = halo_size * TEXTURE_PIXEL_SIZE;
	vec2 grow = vec2(1.0) + 2.0 * margin;
	VERTEX *= grow;
	UV = (UV - 0.5) * grow + 0.5;
}

// 1.0 inside the texture rect, 0.0 outside. Alpha samples are multiplied by
// this so the grown quad's margin doesn't smear the clamped edge pixels.
// (Kept sampler-free: passing TEXTURE into a function is unsupported.)
float in_bounds(vec2 uv) {
	vec2 s = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	return s.x * s.y;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV) * in_bounds(UV);
	vec4 out_col = col;

	if (dutchman_strength > 0.0) {
		// Desaturate, then tint the sprite toward the muted green.
		float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		vec3 ghost_rgb = ghost_color.rgb * (lum * 1.4 + 0.15);

		vec2 ps = TEXTURE_PIXEL_SIZE;

		// Rim detection: compare this pixel's alpha against its neighbours.
		float maxa = col.a;
		float mina = col.a;
		for (int i = 0; i < 8; i += 2) {
			vec2 p = UV + DIRS[i] * glow_width * ps;
			float a = texture(TEXTURE, p).a * in_bounds(p);
			maxa = max(a, maxa);
			mina = min(a, mina);
		}
		float rim = maxa - mina;

		// Slow spectral pulse.
		float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed);

		// Soft halo around the silhouette: for pixels outside the hull, look
		// back toward it at increasing radii; closer hull = stronger halo.
		float halo = 0.0;
		for (int i = 0; i < 8; i++) {
			for (int j = 1; j <= 4; j++) {
				float frac = float(j) / 4.0;
				vec2 p = UV + DIRS[i] * halo_size * frac * ps;
				float a = texture(TEXTURE, p).a * in_bounds(p);
				halo = max(halo, a * (1.0 - frac * 0.85));
			}
		}
		halo *= 1.0 - col.a;

		vec4 dutchman = vec4(ghost_rgb, col.a * ghost_alpha);
		dutchman.rgb += glow_color.rgb * rim * glow_intensity * pulse;
		// Faint inner glow so the whole hull breathes with the pulse.
		dutchman.rgb += glow_color.rgb * 0.12 * pulse * col.a;

		// Composite the halo behind the hull.
		dutchman.rgb = mix(glow_color.rgb, dutchman.rgb, clamp(col.a * 4.0, 0.0, 1.0));
		dutchman.a = max(dutchman.a, halo * halo_strength * pulse);

		out_col = mix(col, dutchman, dutchman_strength);
	}

	// Hit flash paints over everything, including Dutchman mode.
	if (flash_active) {
		out_col.rgb = vec3(1.0);
	}

	COLOR = out_col * v_modulate;
}
