precision highp float;

uniform vec2 u_resolution;

// https://stackoverflow.com/questions/34627576/why-did-glsl-change-varying-to-in-out
out vec2 st;


void main() {
    st = (position.xy - 0.5) * u_resolution / min(u_resolution.x, u_resolution.y); // map uv to -0.5~0.5
    gl_Position = vec4(position * 2. - 1., 1.);
}