precision highp float;
precision highp sampler3D;
// defines
#define Pi 3.14159265359
#define RAY_MARCHING_STEPS 25.
#define RAY_MARCHING_MAX_DIST 100.
#define EPSILON 0.001
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
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float normalization = 0.0;
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * Noise(frequency * p);
        normalization += amplitude;
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    // value /= normalization;
    // value = value * 0.8 + 0.1;
    // value = pow(value, 3.0);
    return value;
}

float SDSphere(vec3 p, float r) {
    // r += FBM(p);
    return length(p - vec3(uPlanetOrigin, 0.)) - r;
}

float RayMarching(vec3 ro, vec3 rd) {
    float d = 0.; // marching dist
    for (float i = 0.; i < RAY_MARCHING_STEPS; i++) {
        vec3 p = ro + rd * d;
        float dist = SDSphere(p, uPlanetRadius);
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

float DeltaDist(vec3 p1, vec3 p2) {
    float r1 = uPlanetRadius + FBM(p1);
    float r2 = uPlanetRadius + FBM(p2);
    return SDSphere(p1, r1) - SDSphere(p2, r2);
}

vec3 EstimateNormal(vec3 p) {
    return normalize(vec3(
        DeltaDist(vec3(p.x + EPSILON, p.y, p.z), vec3(p.x - EPSILON, p.y, p.z)),
        DeltaDist(vec3(p.x, p.y + EPSILON, p.z), vec3(p.x, p.y - EPSILON, p.z)),
        DeltaDist(vec3(p.x, p.y, p.z + EPSILON), vec3(p.x, p.y, p.z - EPSILON))
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
    vec3 ambientLight = 0.5 * vec3(1., 1., 1.);
    vec3 color = ambientLight * k_a;
    vec3 lightPos = 5.0 * vec3(sin(t), 0.0, cos(t));
    // vec3 lightPos = 5.0 * vec3(0.0, 5.0, 1.0);
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
    // return PlanetMaterial(vec3(1.0), 1.0);
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
    vec3 k_s = vec3(0.8)*planetMaterial.specularFactor;
    float shininess = 2.;

    // vec3 col = vec3(p.z, pow(p.z, 2.0), pow(p.z, 3.0));

    vec3 col = PhongIllumination(k_a, k_d, k_s, p, ro, shininess);


    gl_FragColor = vec4(col, 1.0);
}