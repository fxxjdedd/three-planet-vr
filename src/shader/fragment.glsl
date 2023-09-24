precision highp float;
precision highp sampler3D;
// defines
#define Pi 3.14159265359
#define RAY_MARCHING_STEPS 25.
#define RAY_MARCHING_MAX_DIST 100.
#define EPSILON 0.0001
#define OCTAVES 6
#define t uTime * 0.8

// defines for planet colors
#define OCEAN_COLOR vec3(0.02, 0.12, 0.3)

// global uniforms
uniform float uTime;
uniform vec2 uResolution;

// uniforms
uniform vec2 uPlanetOrigin;
uniform float uPlanetRadius;
uniform sampler3D map;

// https://stackoverflow.com/questions/34627576/why-did-glsl-change-varying-to-in-out
in vec2 st;

struct PlanetMaterial {
    vec3 diffuseColor;
    float specularFactor;
};

float Noise(vec3 p) {
    float n = texture(map, p).r;
    return n;
}

// https://thebookofshaders.com/13/

float FBM(in vec3 p) {
    float v = 0.0;
    float a = 0.5;
    float f = 1.0;
    for (int i = 0; i < OCTAVES; i++) {
        v += a * Noise(f * p);
        f *= 2.0;
        a *= 0.5;
    }
    return v;
}

float SDSphere(vec3 p) {
    float r = uPlanetRadius;
    // r += FBM(p);
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

vec3 EstimateNormal(vec3 p) {
    return normalize(vec3(
        SDSphere(vec3(p.x + EPSILON, p.y, p.z)) - SDSphere(vec3(p.x - EPSILON, p.y, p.z)),
        SDSphere(vec3(p.x, p.y + EPSILON, p.z)) - SDSphere(vec3(p.x, p.y - EPSILON, p.z)),
        SDSphere(vec3(p.x, p.y, p.z + EPSILON)) - SDSphere(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

vec3 PhongContrib(vec3 k_d, vec3 k_s, vec3 p, vec3 lightPos, vec3 eyePos, vec3 lightIntensity, float shininess) {
    vec3 N = EstimateNormal(p);
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eyePos - p);
    vec3 R = normalize(reflect(-L, N));

    float diffuse = dot(L, N);
    float specular = dot(R, V);

    if (diffuse < 0.0) {
        return vec3(0., 0., 0.);
    }
    if (specular < 0.0) {
        return lightIntensity * (k_d * diffuse);
    }

    return lightIntensity * (k_d * diffuse + k_s * pow(specular, shininess));
}

vec3 PhongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, vec3 p, vec3 eyePos, float shininess) {
    const vec3 ambientLight = 0.5 * vec3(1., 1., 1.);
    vec3 color = ambientLight * k_a;
    vec3 lightPos = 5.0 * vec3(sin(t), 0.0, cos(t));
    float rad = (90. + 60.) / 180. * Pi;
    mat2 rotate = mat2(
        vec2(cos(rad), sin(rad)),
        vec2(-sin(rad), cos(rad))
    );
    lightPos.xy = rotate * lightPos.xy;

    vec3 lightIntensity = vec3(0.4, 0.4, 0.4);
    color += PhongContrib(k_d, k_s, p, lightPos, eyePos, lightIntensity, shininess);
    return color;
}

PlanetMaterial Planet(vec3 p) {
    float fbm = FBM(p);
    vec3 color = OCEAN_COLOR;
    color = mix(color, vec3(1.0), smoothstep(0.5, 0.55, fbm));

    float specularFactor = smoothstep(0.55, 0.5, fbm);

    return PlanetMaterial(color, specularFactor);
}

void main() {
    vec2 uv = st;
    vec3 ro = vec3(0., 0., 5.);
    vec3 rd = vec3(uv.x, uv.y, -1.);

    float dist = RayMarching(ro, rd);
    if (dist >= RAY_MARCHING_MAX_DIST) {
        gl_FragColor = vec4(vec3(0.0), 1.0);
        return;
    }

    vec3 p = ro + rd * dist;

    PlanetMaterial planetMaterial = Planet(p);

    vec3 k_a = vec3(0.3); 
    vec3 k_d = planetMaterial.diffuseColor;
    vec3 k_s = vec3(1.0)*planetMaterial.specularFactor;
    float shininess = 10.;

    // vec3 col = vec3(p.z, pow(p.z, 2.0), pow(p.z, 3.0));
    vec3 col = PhongIllumination(k_a, k_d, k_s, p, ro, shininess);
    gl_FragColor = vec4(col, 1.0);
}