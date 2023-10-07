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
        uPlanetRadius: { value: 0.5 }, // 3d-noise texture的范围是0-1，0.5的radius正合适，如果是1.0的radius就会有过多的uv-clamp
        map: { value: noiseTexture },
    },
});

startRenderLoop();
