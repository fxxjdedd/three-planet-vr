import { useShaderCanvas } from './useShaderCanvas';
import fragment from './shader/fragment.glsl';
import vertex from './shader/vertex.glsl';

const canvas = document.querySelector('#shader-canvas') as HTMLCanvasElement;

const { startRenderLoop } = useShaderCanvas(canvas, {
    vertexShader: vertex,
    fragmentShader: fragment,
    uniforms: {
        uPlanetOrigin: { value: [0, 0] },
        uPlanetRadius: { value: 0.5 },
    },
});

startRenderLoop();
