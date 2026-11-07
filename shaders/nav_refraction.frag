// Liquid-glass edge refraction for the bottom navigation bar (T38 round 3
// pilot). Applied as the outermost stage of the nav bar's backdrop filter:
// it receives the already blurred + saturation-boosted backdrop and bends
// the sampling coordinates near the capsule rim, so background content
// appears to refract around the edge like a lens rim. The centre of the
// bar is left untouched (offset falls to zero away from the rim band).
//
// This is a static UV displacement, not a physical light simulation; it is
// deliberately confined to the rim band and can be disabled at runtime via
// GlassEffects.refractionEnabled.

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uSize;
uniform float uRadius;
uniform float uBand;
uniform float uStrength;

out vec4 fragColor;

float sdRoundBox(vec2 p, vec2 halfSize, float r) {
  vec2 q = abs(p) - halfSize + vec2(r);
  return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 pos = FlutterFragCoord().xy;
  vec2 halfSize = uSize * 0.5;
  vec2 p = pos - halfSize;
  float d = sdRoundBox(p, halfSize, uRadius);
  float inside = -d; // distance to the rim, >= 0 inside the capsule
  vec2 offset = vec2(0.0);
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
      float falloff = t * t * (3.0 - 2.0 * t);
      // Sample from deeper inside the capsule: edge content stretches
      // around the rim, which reads as refraction at the glass edge.
      offset = -outward * falloff * uStrength;
    }
  }
  vec2 uv = (pos + offset) / uSize;
  fragColor = texture(uTexture, uv);
}
