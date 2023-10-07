precision highp float;
precision highp sampler3D;
// defines
#define Pi 3.14159265359
#define RAY_MARCHING_STEPS 25.
#define RAY_MARCHING_MAX_DIST 100.
#define EPSILON 0.0001 // TODO: RayMarching会产生圆环波纹，待处理
#define OCTAVES 6
#define t uTime * 0.1
#define CAMERA_POSITION vec3(0., 0., 1.5)
#define AtmosphereRadius uPlanetRadius + 0.1

// defines for planet colors
#define OCEAN_COLOR vec3(0.05, 0.15, 0.32)

// global uniforms
uniform float uTime;
uniform vec2 uResolution;

// uniforms
uniform vec2 uPlanetOrigin;
uniform float uPlanetRadius;
uniform vec3 uAtmosphereColor;
uniform sampler3D map;

// https://stackoverflow.com/questions/34627576/why-did-glsl-change-varying-to-in-out
in vec2 st;

mat3 RotateY(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat3(
    vec3(c, 0, s),
    vec3(0, 1, 0),
    vec3(-s, 0, c)
  );
}

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
    return value;
}

float SDSphere(vec3 p, float r) {
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

float PlanetDist(vec3 p) {
    float r = uPlanetRadius + FBM(p);
    return SDSphere(p, r);
}

vec3 EstimateNormal(vec3 p) {
    return normalize(vec3(
        PlanetDist(vec3(p.x + EPSILON, p.y, p.z)) - PlanetDist(vec3(p.x - EPSILON, p.y, p.z)),
        PlanetDist(vec3(p.x, p.y + EPSILON, p.z)) - PlanetDist(vec3(p.x, p.y - EPSILON, p.z)),
        PlanetDist(vec3(p.x, p.y, p.z + EPSILON)) - PlanetDist(vec3(p.x, p.y, p.z - EPSILON))
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
    // fbm based color will be wired if we rotate light
    // vec3 lightPos = 5.0 * vec3(sin(t), 0.0, cos(t));
    vec3 lightPos = vec3(1.0, 1.0, 0.0);
    vec3 lightIntensity = 2.*vec3(0.4, 0.4, 0.4);
    color += PhongContrib(k_d, k_s, p, lightPos, eyePos, lightIntensity, shininess);
    return color;
}

PlanetMaterial Planet(vec3 p) {
    float fbm = FBM(p);
    vec3 color = OCEAN_COLOR;
    color = mix(color, vec3(0.35, 0.55, 0.1), smoothstep(0.5, 0.55, fbm));
    color = mix(color, vec3(0.45, 0.35, 0.23), smoothstep(0.55, 0.6, fbm));
    color = mix(color, vec3(1.0), smoothstep(0.6, 0.65, fbm));

    float specularFactor = smoothstep(0.0, 0.5, fbm);

    return PlanetMaterial(color, 0.5);
}

vec3 Atmosphere(vec3 ro, vec3 rd) {
    vec3 origin = vec3(uPlanetOrigin, 0.0);
    float distCameraToPlanetOrigin = length(CAMERA_POSITION - origin);
    float distCameraToPlanetEdge = sqrt(distCameraToPlanetOrigin*distCameraToPlanetOrigin - uPlanetRadius*uPlanetRadius);
    vec3 coordFromCenter = ro + rd*distCameraToPlanetEdge - origin;
    float distFromEdge = abs(length(coordFromCenter) - uPlanetRadius);
    float planetEdge = max(1.0 - distFromEdge, 0.0);
    vec3 atmosphere = vec3(pow(planetEdge, 80.));
    float planetMask = 1.0;
    atmosphere += pow(planetEdge, 30.) * (1.5 - planetMask);
    atmosphere += pow(planetEdge, 4.) * .02;
    atmosphere += pow(planetEdge, 2.) * .1 * planetMask;
    return atmosphere * uAtmosphereColor;
}

void main() {
    vec2 uv = st;
    vec3 ro = CAMERA_POSITION;
    vec3 rd = vec3(uv.x, uv.y, -1.);

    vec3 col;
    float dist = RayMarching(ro, rd);
    vec3 p = ro + rd * dist;
    p = RotateY(t * -1.) * p;

    if (dist >= RAY_MARCHING_MAX_DIST) {
        col = vec3(0.0);
    } else {
        PlanetMaterial planetMaterial = Planet(p);

        vec3 k_a = vec3(0.1); 
        vec3 k_d = planetMaterial.diffuseColor;
        vec3 k_s = vec3(1.0)*planetMaterial.specularFactor;
        float shininess = 10.;

        // vec3 col = vec3(p.z, pow(p.z, 2.0), pow(p.z, 3.0));
        col = PhongIllumination(k_a, k_d, k_s, p, ro, shininess);
    }

    vec3 atmo = Atmosphere(ro, rd);
    // col = mix(col, vec3(0.2, 0.4, 0.8), atmo);
    // col = vec3(abs(0.0), 1.0, 1.0);
    col += atmo;

    gl_FragColor = vec4(col, 1.0);
}