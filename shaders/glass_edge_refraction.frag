// Liquid-glass edge refraction for card surfaces (T83 prototype).
//
// The structural opposite of the current glass (T64 rounds 4–7): there
// the whole face is gaussian-blurred, which is frosted glass by
// construction and failed three real-device verdicts («不够透亮、
// 晶莹»). Real liquid glass keeps the face clear and bends light only
// in the bevel — the sloped rim band of the pane. This shader does
// exactly that as the ONLY stage of the card's backdrop filter:
//
//   * Face (inside, beyond the bevel band): samples the backdrop
//     exactly as-is (round 2: uFaceBlur is 0 — the face is fully
//     clear, content stays recognisable through the pane).
//   * Bevel band (round 2: a narrow ~8px band at the rim, no longer
//     scaled off the corner radius): sampling coordinates are
//     displaced along the SDF gradient with a sharp pow() peak —
//     strongest AT the rim, collapsing to near-zero within a few
//     pixels — so the bend reads as hard cut glass, not the soft,
//     wide, elastic warp round 1 was judged as («像果冻»).
//   * Cut-glass edge lines, computed from the geometric SDF (never
//     displaced, so they stay crisp): a sharp specular bright line
//     just inside the rim (uRimColor) and a fine dark line where
//     the bevel meets the face, slightly dimming the sample. The
//     bright/dark pair is the contrast that makes an edge read as
//     cut glass rather than a soft glow.
//   * Tint: an extremely light dye mixed over the sample (uniform
//     entry reserved for T82's theme-following tint); round 2 drops
//     it to near zero so the face carries no colour of its own.
//
// This is a static UV displacement, not a physical light simulation.
// Applied via BackdropFilter(ImageFilter.shader) on Impeller; any
// failure to load or build the filter degrades to the current
// GlassSurface rendering (see GlassEdgeRefraction in
// lib/widgets/glass_prototype.dart).

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uSize;
uniform float uRadius;
uniform float uBand;
uniform float uStrength;
uniform float uFaceBlur;
uniform vec4 uTint;
uniform vec4 uRimColor;

out vec4 fragColor;

float sdRoundBox(vec2 p, vec2 halfSize, float r) {
  vec2 q = abs(p) - halfSize + vec2(r);
  return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// Face sampling: identity when uFaceBlur is ~0, otherwise a 9-tap
// tent blur of the given radius (in pixels). Weights sum to 1.
vec4 sampleFace(vec2 uv, vec2 texel) {
  if (uFaceBlur <= 0.01) {
    return texture(uTexture, uv);
  }
  vec2 o = texel * uFaceBlur;
  vec4 c = texture(uTexture, uv) * 0.25;
  c += texture(uTexture, uv + vec2(o.x, 0.0)) * 0.125;
  c += texture(uTexture, uv - vec2(o.x, 0.0)) * 0.125;
  c += texture(uTexture, uv + vec2(0.0, o.y)) * 0.125;
  c += texture(uTexture, uv - vec2(0.0, o.y)) * 0.125;
  c += texture(uTexture, uv + o) * 0.0625;
  c += texture(uTexture, uv - o) * 0.0625;
  c += texture(uTexture, uv + vec2(o.x, -o.y)) * 0.0625;
  c += texture(uTexture, uv + vec2(-o.x, o.y)) * 0.0625;
  return c;
}

void main() {
  vec2 pos = FlutterFragCoord().xy;
  vec2 halfSize = uSize * 0.5;
  vec2 p = pos - halfSize;
  float d = sdRoundBox(p, halfSize, uRadius);
  float inside = -d; // distance to the rim, >= 0 inside the pane
  vec2 offset = vec2(0.0);
  float bevel = 0.0;
  if (inside >= 0.0 && inside < uBand) {
    float e = 1.0;
    float gx = sdRoundBox(p + vec2(e, 0.0), halfSize, uRadius) -
        sdRoundBox(p - vec2(e, 0.0), halfSize, uRadius);
    float gy = sdRoundBox(p + vec2(0.0, e), halfSize, uRadius) -
        sdRoundBox(p - vec2(0.0, e), halfSize, uRadius);
    vec2 grad = vec2(gx, gy);
    float gl = length(grad);
    if (gl > 0.0001) {
      vec2 outward = grad / gl;
      float t = 1.0 - inside / uBand;
      // Round 2: sharp peak, fast decay (pow 3.5) — the displacement
      // lives in the outer ~3px of the band and is effectively zero
      // at the face, a hard bend instead of round 1's smooth warp.
      float falloff = pow(t, 3.5);
      // Sample from deeper inside the pane: edge content stretches
      // around the rim, which reads as refraction at the bevel.
      offset = -outward * falloff * uStrength;
      bevel = falloff;
    }
  }
  vec2 uv = (pos + offset) / uSize;
  vec4 col = sampleFace(uv, 1.0 / uSize);
  // Bent-light lift: the bevel catches light, so it reads a touch
  // brighter than the face. Kept very subtle — the rim light proper
  // is still painted by the surface's Dart overlays.
  col.rgb += bevel * 0.04;
  // The pane's dye: near zero in round 2 (the face must stay clear);
  // the uniform is the T82 theme-tint entry point.
  col.rgb = mix(col.rgb, uTint.rgb, uTint.a);
  if (inside >= 0.0) {
    // Cut-glass edge lines from the geometric distance (undisplaced,
    // so both lines stay 1px-crisp around the whole perimeter).
    // Dark line first: a fine shadow where the bevel meets the face,
    // centred just inside the band's inner edge.
    float dd = inside - (uBand - 0.8);
    float darkLine = exp(-(dd * dd) / 1.28); // sigma 0.8px
    col.rgb *= 1.0 - darkLine * 0.16;
    // Specular line last so the rim itself stays the brightest
    // element: a ~1px bright peak centred just inside the rim.
    float bd = inside - 0.8;
    float brightLine = exp(-(bd * bd) / 0.72); // sigma 0.6px
    col.rgb = mix(col.rgb, uRimColor.rgb, brightLine * uRimColor.a * 0.85);
  }
  fragColor = vec4(col.rgb, col.a);
}
