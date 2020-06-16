//
//  Shader.metal
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/16.
//  Copyright © 2020 davidandty. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "DwShaderType.h"

typedef struct {
    float4 position [[position]];
    float4 color;
}RasterizerData;


vertex RasterizerData vertexDrawShapeShader(constant DwVertex *vertices[[buffer(0)]], uint vid[[vertex_id]]) {
    
    RasterizerData outData;
    outData.position = float4(vertices[vid].position, 0.0, 1.0);
    outData.color = vertices[vid].color;
    
    return outData;
}


fragment float4 fragmentDrawShapeShader(RasterizerData inVertex [[stage_in]]) {
    return inVertex.color;
}
