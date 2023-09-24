import { Data3DTexture, LinearFilter, MirroredRepeatWrapping, RedFormat, RepeatWrapping, Vector3 } from 'three';
import { ImprovedNoise } from 'three/examples/jsm/math/ImprovedNoise';
export function useNoiseTexture() {
    const size = 32;
    const data = new Uint8Array(size * size * size);

    let i = 0;
    const noise = new ImprovedNoise();
    const vec3 = new Vector3();

    for (let x = 0; x < size; x++) {
        for (let y = 0; y < size; y++) {
            for (let z = 0; z < size; z++) {
                vec3.set(x, y, z).divideScalar(size).multiplyScalar(10.5);
                const d = noise.noise(vec3.x, vec3.y, vec3.z);
                data[i++] = d * 128 + 128;
            }
        }
    }

    const texture = new Data3DTexture(data, size, size, size);
    texture.format = RedFormat;
    texture.minFilter = LinearFilter;
    texture.magFilter = LinearFilter;
    texture.unpackAlignment = 1;
    texture.needsUpdate = true;
    texture.wrapS = RepeatWrapping;
    texture.wrapT = RepeatWrapping;
    texture.wrapR = RepeatWrapping;

    // texture.wrapS = MirroredRepeatWrapping;
    // texture.wrapT = MirroredRepeatWrapping;
    // texture.wrapR = MirroredRepeatWrapping;

    return texture;
}
