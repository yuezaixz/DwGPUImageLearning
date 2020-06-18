//
//  MetaRotatingCubeView.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/18.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import MetalKit

class MetaRotatingCubeView: MTKView {
    
    var commandQueue: MTLCommandQueue?
    var rps: MTLRenderPipelineState?
    var vertexData: [Float]?
    var vertexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    
    var rotation: Float = 0
    
    // MTKView的深度depth那是多少呢？宽高可以理解成frame*screenScale，那深度呢？
    var scales: [Float] = [0.5, 0.5, 0.5]
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        device = MTLCreateSystemDefaultDevice()
        setupBuffers()
        setupShaders()
        
//        let screenWidth = UIScreen.main.bounds.width
//        let screenHeight = UIScreen.main.bounds.height
//        let radio = screenHeight / screenWidth
//        scales[1] = scales[0] / Float(radio)
//        
//        // FIXME?
//        scales[2] = 0.4
    }
    
    func setupBuffers() {
        let vertexData = [
            Vertex(pos: [-1.0, -1.0,  1.0, 1.0], col: [1, 0, 0, 1]),
            Vertex(pos: [ 1.0, -1.0,  1.0, 1.0], col: [0, 1, 0, 1]),
            Vertex(pos: [ 1.0,  1.0,  1.0, 1.0], col: [0, 0, 1, 1]),
            Vertex(pos: [-1.0,  1.0,  1.0, 1.0], col: [1, 1, 1, 1]),
            Vertex(pos: [-1.0, -1.0, -1.0, 1.0], col: [0, 0, 1, 1]),
            Vertex(pos: [ 1.0, -1.0, -1.0, 1.0], col: [1, 1, 1, 1]),
            Vertex(pos: [ 1.0,  1.0, -1.0, 1.0], col: [1, 0, 0, 1]),
            Vertex(pos: [-1.0,  1.0, -1.0, 1.0], col: [0, 1, 0, 1])
        ]
        let indexData: [UInt16] = [
            0, 1, 2, 2, 3, 0,
            1, 5, 6, 6, 2, 1,
            3, 2, 6, 6, 7, 3,
            4, 5, 1, 1, 0, 4,
            4, 0, 3, 3, 7, 4,
            7, 6, 5, 5, 4, 7,
        ]
        
        commandQueue = device?.makeCommandQueue()
        
        indexBuffer = device!.makeBuffer(bytes: indexData, length: MemoryLayout<UInt16>.size * indexData.count, options: [])
        vertexBuffer = device!.makeBuffer(bytes: vertexData, length: MemoryLayout<Vertex>.size * 8, options:[])
        
        uniformBuffer = device!.makeBuffer(length: MemoryLayout<matrix_float4x4>.size, options: [])
    }
    
    func updateUniforms() {
        let scaled = scalingMatrix(scaleX: scales[0], scaleY: scales[1], scaleZ: scales[2])
        rotation += 1 / 100 * Float.pi / 4
        let rotatedY = rotationMatrix(angle: rotation, axis: SIMD3<Float>(0, 1, 0))
        let rotatedX = rotationMatrix(angle: rotation, axis: SIMD3<Float>(1, 0, 0))
        let modelMatrix = matrix_multiply(matrix_multiply(rotatedX, rotatedY), scaled)
        let cameraPosition = vector_float3(0, 0, -3)
        let viewMatrix = translationMatrix(position: cameraPosition)
        let aspect = Float(drawableSize.width / drawableSize.height)
        let projMatrix = projectionMatrix(near: 1, far: 100, aspect: aspect, fovy: 1.1)
        let modelViewProjectionMatrix = matrix_multiply(projMatrix, matrix_multiply(viewMatrix, modelMatrix))
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
    }
    
    func setupShaders() {
        do {
            // 加载着色器程序
            let library = device?.makeDefaultLibrary()!
            let vertexFunc = library?.makeFunction(name: "mtkDrawCubeVertex")
            let fragFunc = library?.makeFunction(name: "mtkDrawCubeFragment")
            let rpld = MTLRenderPipelineDescriptor()
            rpld.vertexFunction = vertexFunc
            rpld.fragmentFunction = fragFunc
            rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            rps = try device!.makeRenderPipelineState(descriptor: rpld)
        } catch let e {
            print("\(e.localizedDescription)")
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        updateUniforms()
        // commandBuffer和commandEncoder是一次性对象，每帧创建
        if let drawable = currentDrawable, let rpd = currentRenderPassDescriptor, let commandQueue = commandQueue, let commandBuffer = commandQueue.makeCommandBuffer() {
            rpd.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
            commandEncoder?.setRenderPipelineState(rps!)
            commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            commandEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
            commandEncoder?.setFrontFacing(.counterClockwise)

            commandEncoder?.setCullMode(.back)
            commandEncoder?.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.size, indexType: MTLIndexType.uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
            commandEncoder?.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
