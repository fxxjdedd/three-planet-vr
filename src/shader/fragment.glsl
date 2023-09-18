
// https://stackoverflow.com/questions/34627576/why-did-glsl-change-varying-to-in-out
in vec2 st;

void main() {
    gl_FragColor = vec4(st.x, 0.0, 0.0, 1.0);
}