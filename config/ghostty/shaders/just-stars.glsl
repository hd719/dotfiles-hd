// Pixel-art twinkling stars for Ghostty.
// Inspired by "Just snow" by Andrew Baldwin (2013) — https://www.shadertoy.com/
//   Original: twitter @baldand, www.thndl.com
// Adapted into a starfield (density-gated cells, sin-free triangular twinkle,
// pixel-snapped plus-shaped stars) by Eli Saliman with Claude (2026).
// License: CC BY-NC-SA 3.0 — http://creativecommons.org/licenses/by-nc-sa/3.0/

#define LAYERS      10
#define DEPTH       0.75
// Thinned out from the upstream 0.01.
#define DENSITY     0.002
#define SPEED       0.3
#define PIXEL_SIZE  0.7
#define SKIP_NEAR   2

// Local addition: fade the field toward the corners so they stay empty.
// Distances are in normalized screen units from the centre, so the falloff is
// an ellipse inscribed in the window; the corners are its farthest points at
// 0.707. Stars are at full strength inside VIGNETTE_START and gone by
// VIGNETTE_END.
#define VIGNETTE_START 0.50
#define VIGNETTE_END   0.72

const vec3 STAR_COLOR = vec3(0.85, 0.92, 1.0);

// Sin-free 1D hash
float hash1(float n) {
    n = fract(n * 0.1031);
    n *= n + 33.33;
    return fract(n * 2.0);
}

// Cheap 3-component 2D hash
vec3 hash3(vec2 p, float seed) {
    vec3 q = vec3(dot(p, vec2(127.1, 311.7)),
                  dot(p, vec2(269.5, 183.3)),
                  dot(p, vec2(419.2, 371.9)));
    q = fract(q * 0.1031 + seed * 0.0937);
    q *= q + 33.33;
    return fract(q * q);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Keep normal UVs for sampling the terminal texture.
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Top-left anchored star coordinates.
    // This makes placement stable when the terminal grows/shrinks vertically.
    vec2 starCoord = vec2(fragCoord.x, iResolution.y - fragCoord.y);

    // Pixel snap in top-left anchored space.
    vec2 snapped = (floor(starCoord / PIXEL_SIZE) + 0.5) * PIXEL_SIZE;

    // Absolute pixel-grid coordinates.
    // No normalized resolution here, so resizing reveals more/less of the same sky.
    vec2 world = snapped / PIXEL_SIZE;

    float acc = 0.0;

    for (int i = SKIP_NEAR; i < LAYERS; i++) {
        float fi = float(i);

        // Larger number = more spread out stars.
        // Layer variation gives a little depth while staying resolution-independent.
        float cellSize = 10.0 + fi * 3.0;

        vec2 q = world / cellSize;

        vec2 cellId  = floor(q);
        vec2 cellPos = q - cellId;
        vec3 r       = hash3(cellId, fi);

        // Not every cell gets a star.
        if (r.z > DENSITY) continue;

        vec2 center = 0.15 + 0.7 * r.xy;

        vec2 off = cellPos - center;
        float ax = abs(off.x);
        float ay = abs(off.y);

        // Convert pixel-sized star shape into cell-local units.
        float px = 1.0 / cellSize;

        float armScale = 1.0 - fi / float(LAYERS);
        float coreSize = px * 0.55;
        float armLen   = px * (0.7 + 1.8 * armScale);
        float thick    = px * 0.45;

        // Bounding-box early out.
        float bbox = max(armLen, coreSize);
        if (ax > bbox || ay > bbox) continue;

        // Pixelated plus/star shape.
        float core = step(ax, coreSize) * step(ay, coreSize);
        float h    = step(ax, armLen) * step(ay, thick);
        float v    = step(ay, armLen) * step(ax, thick);

        float star = max(core, max(h, v));

        // Twinkle.
        float phase = hash1(fi * 9.17 + r.x * 31.3 + r.y * 71.9) * 10.0;
        float rate  = 0.4 + 1.8 * hash1(fi * 2.83 + r.z * 19.7);

        float t = fract(iTime * SPEED * rate + phase);
        float tri = 1.0 - abs(t * 2.0 - 1.0);

        // Smooth triangular pulse.
        float twinkle = tri * tri * (3.0 - 2.0 * tri);

        // Some stars stay dim, some flare brighter. The floor is raised from
        // the upstream 0.15 so the quiet ones still read against the Nord
        // background now that there are far fewer of them.
        float base  = 0.35 + 0.35 * hash1(r.x * 53.1 + fi);
        float flare = 0.65 * twinkle;

        float depthFade = 1.0 / (1.0 + fi * 0.08);
        float alpha = (base + flare) * depthFade;

        acc = max(acc, star * alpha);
    }

    acc *= 1.0 - smoothstep(VIGNETTE_START, VIGNETTE_END, length(uv - 0.5));

    vec4 terminal = texture(iChannel0, uv);
    fragColor = vec4(terminal.rgb + STAR_COLOR * acc, terminal.a);
}
