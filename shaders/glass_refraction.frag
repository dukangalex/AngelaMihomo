// Liquid glass surface shader: clear face, refraction only in the edge
// bevel band, uneven rim light and a diagonal sheen film.
//
// Design lineage (see TASKS T83/T64): full-face uniform blur reads as
// frosted glass, so the face samples the backdrop untouched apart from a
// crystal lift (contrast / saturation / brightness). Refraction lives in
// a narrow bevel band (~8px) with a spiked falloff so the bend is hard,
// not jelly. The rim carries one sharp bright line whose intensity is
// uneven (top and corners strongest, fading downward) plus a thin dark
// line at the inner band edge, which together read as cut crystal.

#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uRadius;
uniform vec4 uTint; // rgb: face tint color, a: face tint alpha
uniform vec3 uRimColor;
uniform float uBand; // bevel band width in px
uniform float uStrength; // max backdrop displacement in px
uniform float uSheen; // diagonal sheen strength 0..1
uniform float uRimAlpha; // rim bright line strength 0..1
uniform float uContrast;
uniform float uSaturate;
uniform float uBright;

uniform sampler2D uTexture;

out vec4 fragColor;

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - (b - r);
  return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / uSize;
  vec2 p = fragCoord - uSize * 0.5;
  float d = sdRoundBox(p, uSize * 0.5, uRadius);
  float edgeDist = -d; // >0 inside, 0 at the rim

  // Bevel band factor: 1 at the rim, 0 at the inner band edge.
  float bandT = 1.0 - clamp(edgeDist / max(uBand, 1.0), 0.0, 1.0);
  float spike = pow(bandT, 3.5);

  // SDF gradient (outward normal) for the refraction direction.
  float e = 1.5;
  float gx = sdRoundBox(p + vec2(e, 0.0), uSize * 0.5, uRadius) -
      sdRoundBox(p - vec2(e, 0.0), uSize * 0.5, uRadius);
  float gy = sdRoundBox(p + vec2(0.0, e), uSize * 0.5, uRadius) -
      sdRoundBox(p - vec2(0.0, e), uSize * 0.5, uRadius);
  vec2 grad = vec2(gx, gy);
  float gl = length(grad);
  grad = gl > 1e-4 ? grad / gl : vec2(0.0, -1.0);

  // Bend the sampled backdrop toward the interior near the rim.
  vec2 disp = -grad * spike * uStrength;
  vec3 color;
  color.r = texture(uTexture, (fragCoord + disp * 1.3) / uSize).r;
  color.g = texture(uTexture, (fragCoord + disp) / uSize).g;
  color.b = texture(uTexture, (fragCoord + disp * 0.7) / uSize).b;

  // Crystal lift: contrast / saturation / brightness on the clear face.
  float luma = dot(color, vec3(0.299, 0.587, 0.114));
  color = mix(vec3(luma), color, uSaturate);
  color = (color - 0.5) * uContrast + 0.5 + uBright;

  // Diagonal sheen film: a soft band running top-left to bottom-right,
  // strongest toward the top of the card.
  float diag = uv.x * 0.72 + (1.0 - uv.y) * 0.58;
  float film = exp(-pow((diag - 0.46) * 3.0, 2.0));
  float sheenAmt = film * uSheen * (0.35 + 0.65 * (1.0 - uv.y));
  color += vec3(0.92, 0.97, 1.0) * sheenAmt * 0.16;

  // Uneven rim light: top brightest, corners boosted, fading downward.
  float vertical = mix(0.45, 1.0, 1.0 - uv.y);
  float corner = 0.85 + 0.30 * pow(abs(uv.x * 2.0 - 1.0), 2.0) * (1.0 - uv.y);
  float rimW = vertical * corner;

  // One sharp bright line just inside the rim.
  float line = exp(-pow((edgeDist - 0.9) / 0.7, 2.0));
  color = mix(color, uRimColor * 1.18, clamp(line * uRimAlpha * rimW, 0.0, 1.0));

  // Thin dark line where the bevel meets the face (cut edge).
  float darkLine = exp(-pow((edgeDist - uBand) / 0.9, 2.0));
  color *= 1.0 - 0.13 * darkLine;

  // Near-zero face tint, slightly deeper inside the band.
  color = mix(color, uTint.rgb, uTint.a * (0.55 + 0.45 * bandT));

  fragColor = vec4(color, 1.0);
}
