//
//  MTKDrawShapeShader.metal
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/17.
//  Copyright © 2020 davidandty. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
struct Vertex {
    float4 position [[position]];
};

vertex Vertex mtkDrawTriangleVertex(constant Vertex *vertices [[buffer(0)]],uint vid [[vertex_id]]){
    return vertices[vid];
}

fragment float4 mtkDrawTriangleFragment(Vertex vert [[stage_in]]){
    return float4(1, 0, 0, 1);
}
