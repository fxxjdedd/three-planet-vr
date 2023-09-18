// defines
#define RAY_MARCHING_STEPS 100
#define RAY_MARCHING_MAX_DIST 100.
#define EPSILON 0.001

// global uniforms
uniform float uTime;
uniform vec2 uResolution;

// uniforms
uniform vec2 uPlanetOrigin;
uniform float uPlanetRadius;

// https://stackoverflow.com/questions/34627576/why-did-glsl-change-varying-to-in-out
in vec2 st;


float SDSphere(vec3 p) {
    return length(p - vec3(uPlanetOrigin, 0.)) - uPlanetRadius;
}

float RayMarching(vec3 ro, vec3 rd) {
    float d = 0.;
    for (int i = 0; i < RAY_MARCHING_STEPS; i++) {
        float dist = SDSphere(ro + rd * d);
        if (dist < EPSILON) {
            return d;
        }
        d += dist;
        if (d > RAY_MARCHING_MAX_DIST) {
            return RAY_MARCHING_MAX_DIST;
        }
    }
    return d;
}

void main() {

    vec3 ro = vec3(0., 0., 10.);
    vec3 rd = vec3(st.x, st.y, -1);

    float i = RayMarching(ro, rd);


    gl_FragColor = vec4(i/20., 0.0, 0.0, 1.0);
}