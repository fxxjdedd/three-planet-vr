precision highp float;
precision highp sampler3D;
// defines
#define RAY_MARCHING_STEPS 25.
#define RAY_MARCHING_MAX_DIST 100.
#define EPSILON 0.0001

// global uniforms
uniform float uTime;
uniform vec2 uResolution;

// uniforms
uniform vec2 uPlanetOrigin;
uniform float uPlanetRadius;
uniform sampler3D map;

// https://stackoverflow.com/questions/34627576/why-did-glsl-change-varying-to-in-out
in vec2 st;

float Noise(vec3 p) {
    float n = texture(map, p).r;
    return n;
}

// https://thebookofshaders.com/13/
#define OCTAVES 6
#define t uTime * 0.8
float FBM(in vec3 p) {
    float v = 0.0;
    float a = 0.5;
    float f = 1.0;

    p.z -= t;

    for (int i = 0; i < OCTAVES; i++) {
        v += a * Noise(f * p);
        f *= 2.0;
        a *= 0.5;
    }
    return v;
}

float SDSphere(vec3 p) {
    float r = uPlanetRadius;
    r += FBM(p);
    return length(p - vec3(uPlanetOrigin, 0.)) - r;
}

float RayMarching(vec3 ro, vec3 rd) {
    float d = 0.; // marching dist
    for (float i = 0.; i < RAY_MARCHING_STEPS; i++) {
        float dist = SDSphere(ro + rd * d);
        if (dist < EPSILON) {
            return d;
        }
        d += dist;
        if (d > RAY_MARCHING_MAX_DIST) {
            return RAY_MARCHING_MAX_DIST;
        }
    }
    return RAY_MARCHING_MAX_DIST; // return max dist if exceed RAY_MARCHING_STEPS
}

void main() {
    vec2 uv = st;
    vec3 ro = vec3(0., 0., 10.);
    vec3 rd = vec3(uv.x, uv.y, -1.);

    float dist = RayMarching(ro, rd);
    if (dist >= RAY_MARCHING_MAX_DIST) {
        gl_FragColor = vec4(vec3(0.0), 1.0);
        return;
    }

    vec3 p = ro + rd * dist;
    vec3 col = vec3(p.z, pow(p.z, 2.0), pow(p.z, 3.0));
    gl_FragColor = vec4(col, 1.0);
}