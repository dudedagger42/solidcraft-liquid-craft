// Liquid Craft's glass: a lens at each panel's rim, frost, a specular edge and a hairline.
// From the all-in-one build's egui-glass shader (MIT, (c) 2026 heonny) as SolidCraft changed it.
const LIGHT: vec2<f32> = vec2<f32>(-0.4104, -0.9119);   // normalize(-0.45, -1): from the top left
const CHROMA: f32 = 0.08;
const SPECULAR: f32 = 0.35;
const BORDER: f32 = 0.3;

fn screen(c: vec3<f32>) -> vec3<f32> {
    return pow(max(c, vec3<f32>(0.0)), vec3<f32>(1.0 / 2.2));
}

// What is behind the glass at p, frosted by `amount` (0 sharp .. 1 the manifest's blur).
fn behind(p: vec2<f32>, amount: f32) -> vec3<f32> {
    return screen(mix(sc_backdrop(p).rgb, sc_blurred(p).rgb, amount));
}

fn panel(px: ScPanel) -> vec4<f32> {
    let dark = sc.dark;
    // The card's sliders, as shares of the theme's own glass (percent).
    let blur_share = sc.settings.x / 100.0;
    let bend_share = sc.settings.y / 100.0;
    let reach = clamp(sc.settings.z / 100.0, 0.0, 1.0);
    let accent_share = clamp(sc.settings.w / 100.0, 0.0, 1.0);

    let d = px.edge;
    let n = px.normal;
    let edge_width = clamp(px.radius * 1.5, 16.0 * sc.scale, 36.0 * sc.scale);
    let refraction = mix(12.0, 14.0, dark) * bend_share * sc.scale;
    let blur0 = mix(10.0, 12.0, dark) * blur_share * sc.scale;

    let t = clamp((d + edge_width) / edge_width, 0.0, 1.0);
    let lens = t * t * (3.0 - 2.0 * t);
    let magnify = min(refraction / edge_width, 0.75) * max(-d, 0.0);
    let disp = n * lens * mix(magnify, refraction, reach);

    let band = edge_width * 3.0;
    let rim_frost = smoothstep(0.0, 1.0, clamp((d + band) / band, 0.0, 1.0));
    let frost = clamp(blur0 * mix(0.65, 1.35, rim_frost) / max(px.blur, 1.0), 0.0, 1.0);

    let k = CHROMA * 0.5;
    let p = px.position;
    var col = vec3<f32>(
        behind(p + disp * (1.0 + k), frost).r,
        behind(p + disp, frost).g,
        behind(p + disp * (1.0 - k), frost).b,
    );

    let lum = dot(col, vec3<f32>(0.2126, 0.7152, 0.0722));
    col = mix(vec3<f32>(lum), col, mix(1.05, 0.9, dark)) * mix(0.985, 0.86, dark);
    // Clear glass has a faint white lift; the accent tint takes its place as the slider rises.
    let clear_tint = vec4<f32>(1.0, 1.0, 1.0, mix(80.0, 24.0, dark) / 255.0);
    let accent_tint = vec4<f32>(screen(sc.accent.rgb), mix(26.0, 34.0, dark) / 255.0);
    let glass_tint = mix(clear_tint, accent_tint, accent_share);
    col = mix(col, glass_tint.rgb, glass_tint.a);

    let ndl = dot(n, LIGHT);
    let curved = 4.0 * n.x * n.x * n.y * n.y;
    let rim = pow(t, 10.0) * (0.3 + 0.7 * curved) * (max(ndl, 0.0) + 0.6 * max(-ndl, 0.0));
    col += vec3<f32>(SPECULAR * rim);
    col *= 1.0 - 0.6 * BORDER * pow(t, 8.0) * (0.6 + 0.4 * (1.0 - max(ndl, 0.0)));
    let ring = 1.0 - smoothstep(0.0, 1.2 * sc.scale, abs(d + 0.7 * sc.scale));
    let ring_a = BORDER * ring * (0.32 + 0.4 * max(ndl, 0.0) + 0.18 * max(-ndl, 0.0));
    col = mix(col, vec3<f32>(1.0), ring_a);

    col = clamp(col, vec3<f32>(0.0), vec3<f32>(1.0));
    return vec4<f32>(pow(col, vec3<f32>(2.2)), 1.0);
}
