//
//  CubeShaders.metal
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/18.
//  Copyright © 2020 davidandty. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float4x4 modelViewProjectionMatrix;
};

vertex Vertex mtkDrawCubeVertex(constant Vertex *vertices [[buffer(0)]], constant Uniforms &uniforms [[buffer(1)]], uint vid [[vertex_id]]) {
    float4x4 matrix = uniforms.modelViewProjectionMatrix;
    Vertex in = vertices[vid];
    Vertex out;
    out.position = matrix * float4(in.position);
    out.color = in.color;
    return out;
}

fragment half4 mtkDrawCubeFragment(Vertex vert [[stage_in]]) {
    return half4(vert.color);
}
