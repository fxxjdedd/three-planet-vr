import { useShaderCanvas } from './useShaderCanvas';
import fragment from './shader/fragment.glsl';
import vertex from './shader/vertex.glsl';
import { useNoiseTexture } from './useNoiseTexture';

const canvas = document.querySelector('#shader-canvas') as HTMLCanvasElement;

const noiseTexture = useNoiseTexture();

const { startRenderLoop } = useShaderCanvas(canvas, {
    vertexShader: vertex,
    fragmentShader: fragment,
    uniforms: {
        uPlanetOrigin: { value: [0, 0] },
        uPlanetRadius: { value: 1.0 },
        map: { value: noiseTexture },
    },
});

startRenderLoop();
