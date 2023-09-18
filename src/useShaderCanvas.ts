import {
    BufferAttribute,
    BufferGeometry,
    Mesh,
    PerspectiveCamera,
    Scene,
    ShaderMaterial,
    ShaderMaterialParameters,
    WebGLRenderer,
} from 'three';

export function useShaderCanvas(canvas: HTMLCanvasElement, materialOptions?: ShaderMaterialParameters) {
    const renderer = new WebGLRenderer({ canvas });
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.setSize(window.innerWidth, window.innerHeight);

    const plane = new BufferGeometry();
    // prettier-ignore
    const planeVertex = new BufferAttribute(new Float32Array([
        // right triangle
        0, 0, 0,
        1, 0, 0,
        1, 1, 0,
        // left triangle
        0, 0, 0,
        1, 1, 0,
        0, 1, 0,
    ]), 3)

    plane.setAttribute('position', planeVertex);

    const globalUniforms = {
        uTime: { value: Date.now() / 1000 },
        uResolution: { value: [window.innerWidth, window.innerHeight] },
    };
    const shaderMaterial = new ShaderMaterial({
        ...materialOptions,
        uniforms: {
            ...globalUniforms,
            ...materialOptions?.uniforms,
        },
    });

    const planeMesh = new Mesh(plane, shaderMaterial);

    const scene = new Scene();
    scene.add(planeMesh);

    const camera = new PerspectiveCamera();

    window.addEventListener('resize', onWindowResize);

    function onWindowResize() {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        globalUniforms.uResolution.value = [window.innerWidth, window.innerHeight];
        renderer.setSize(window.innerWidth, window.innerHeight);
    }

    function render() {
        globalUniforms.uTime.value -= Date.now() / 1000;
        globalUniforms.uTime.value *= -1;
        renderer.render(scene, camera);
    }

    function startRenderLoop() {
        requestAnimationFrame(startRenderLoop);
        render();
    }

    return {
        startRenderLoop,
        globalUniforms,
    };
}
