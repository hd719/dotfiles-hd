// Pixel-art twinkling stars for Ghostty.
// Inspired by "Just snow" by Andrew Baldwin (2013) — https://www.shadertoy.com/
//   Original: twitter @baldand, www.thndl.com
// Adapted into a starfield (density-gated cells, sin-free triangular twinkle,
// pixel-snapped plus-shaped stars) by Eli Saliman with Claude (2026).
// License: CC BY-NC-SA 3.0 — http://creativecommons.org/licenses/by-nc-sa/3.0/
//
// Local changes, marked inline below: stars fly outward from the centre instead
// of holding still, a vignette keeps the corners clear, and the pixel-snapped
// plus shape is now a soft round dot. The last one is required by the first —
// hard sub-pixel edges blink rather than glide once anything moves.

#define LAYERS      10
#define DEPTH       0.75
// Fraction of grid cells holding a star. Half the upstream 0.01 in raw terms,
// but the warp contracts the grid and puts roughly half as many cells on screen,
// so the visible count lands a little above the old static field.
#define DENSITY     0.007
// Twinkle rate, slowed hard from the upstream 0.3 so stars breathe rather than
// blink. One pulse now runs tens of seconds.
#define SPEED       0.04
#define PIXEL_SIZE  0.7
#define SKIP_NEAR   2

// Local addition: star radius in screen pixels. Anything under about one pixel
// blinks as it moves rather than gliding, however smooth the falloff.
#define STAR_SIZE   1.8

// Local addition: fly forward through the field. Each layer contracts the grid
// it samples over one cycle, which pushes stars outward from the centre on
// screen. Screen radius goes as 1/zoom, so a linear cycle still accelerates
// outward, and that acceleration is what reads as forward motion rather than a
// sheet sliding past.
//
// WARP_SPEED is cycles per second, so 0.04 is a 25-second trip from spawn to
// fade. WARP_DEPTH is how far the grid contracts by the end; 0.35 means a star
// ends up about 2.9x further from the centre than it started.
#define WARP_SPEED 0.016
#define WARP_DEPTH 0.35

// Local addition: keep the corners empty. Each axis is measured separately and
// the two are multiplied, so the fade only bites where both are near their edge,
// which is what a corner is. The middle of each edge keeps its stars. A radial
// falloff cannot do this: edge midpoints sit at 0.5 and corners at 0.707, close
// enough that clearing the corners dims the edges with them.
//
// The knobs act on that product, which is 0 at the centre and along the middle
// of every edge, and 1 in the corners.
#define CORNER_START 0.15
#define CORNER_END   0.60

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

    // Absolute pixel-grid coordinates.
    // No normalized resolution here, so resizing reveals more/less of the same sky.
    // Upstream snapped this to a PIXEL_SIZE grid for a pixel-art look. That grid
    // is finer than a screen pixel, so once stars move, a hard-edged star lands
    // on a sample or misses it and blinks. Left continuous instead.
    vec2 world = starCoord / PIXEL_SIZE;

    // Measured from the centre, because that is the point stars travel away from.
    vec2 centered = world - (iResolution.xy * 0.5) / PIXEL_SIZE;

    float acc = 0.0;

    for (int i = SKIP_NEAR; i < LAYERS; i++) {
        float fi = float(i);

        // Larger number = more spread out stars.
        // Layer variation gives a little depth while staying resolution-independent.
        float cellSize = 10.0 + fi * 3.0;

        // Layers are staggered across the cycle so stars keep arriving instead
        // of the whole field sweeping past together.
        float trip = fract(iTime * WARP_SPEED + (fi - float(SKIP_NEAR)) / float(LAYERS - SKIP_NEAR));

        // Contracting the sampled grid pushes stars outward on screen.
        float zoom = mix(1.0, WARP_DEPTH, trip);

        // Fade in on arrival and out on departure, so the cycle wrap is
        // invisible rather than the field snapping back to the start.
        float envelope = smoothstep(0.0, 0.2, trip) * (1.0 - smoothstep(0.7, 1.0, trip));
        if (envelope <= 0.0) continue;

        vec2 q = centered * zoom / cellSize;

        vec2 cellId  = floor(q);
        vec2 cellPos = q - cellId;
        vec3 r       = hash3(cellId, fi);

        // Not every cell gets a star.
        if (r.z > DENSITY) continue;

        vec2 center = 0.15 + 0.7 * r.xy;

        vec2 off = cellPos - center;
        float ax = abs(off.x);
        float ay = abs(off.y);

        // Star radius in cell units, worked back from a size in screen pixels.
        // Carrying the zoom through holds that size constant as a star travels
        // outward, so it stays a pinprick instead of blooming into a blob.
        float radius = STAR_SIZE * zoom / (cellSize * PIXEL_SIZE);

        // Bounding-box early out.
        if (ax > radius || ay > radius) continue;

        // Soft round dot. The gradient is the point: coverage changes smoothly
        // as the star crosses a pixel, so motion glides instead of flickering.
        float star = 1.0 - smoothstep(radius * 0.35, radius, length(off));

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
        float alpha = (base + flare) * depthFade * envelope;

        acc = max(acc, star * alpha);
    }

    vec2 edge = abs(uv - 0.5) * 2.0;
    acc *= 1.0 - smoothstep(CORNER_START, CORNER_END, edge.x * edge.y);

    vec4 terminal = texture(iChannel0, uv);
    fragColor = vec4(terminal.rgb + STAR_COLOR * acc, terminal.a);
}
