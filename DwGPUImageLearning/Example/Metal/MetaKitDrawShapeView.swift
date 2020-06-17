//
//  MetaKitDrawShapeView.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/17.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import MetalKit

class MetaKitDrawShapeView: MTKView {
    
    var commandQueue: MTLCommandQueue?
    var rps: MTLRenderPipelineState?
    var vertexData: [Float]?
    var vertexBuffer: MTLBuffer?
    required init(coder: NSCoder) {
        super.init(coder: coder)
        render()
    }
    
    func render() {
        // MTKView带有一个device，直接给他复制
        device = MTLCreateSystemDefaultDevice()
        // 命令缓冲区的串行序列，并确定存储的命令将执行的顺序
        commandQueue = device?.makeCommandQueue()
        // 顶点坐标, x y z w
        vertexData = [-0.5,-0.5,0.0,1.0,
                      0.5,-0.5,0.0,1.0,
                      0.0,0.5,0.0,1.0]
        // 数据总长度
        let dataSize = vertexData!.count * MemoryLayout<Float>.size
        // 创建相应长度的缓冲区
        vertexBuffer = device?.makeBuffer(bytes: vertexData!, length: dataSize, options: [])
        // 加载着色器程序
        let library = device?.makeDefaultLibrary()!
        let vertex_func = library?.makeFunction(name: "mtkDrawTriangleVertex")
        let frag_func = library?.makeFunction(name: "mtkDrawTriangleFragment")
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        // 配置像素格式，以便通过渲染管线的所有内容都符合相同的颜色分量顺序（在本例中为Blue(蓝色)，Green(绿色)，Red(红色)，Alpha(阿尔法)）以及尺寸（在这种情况下，8-bit(8位)颜色值变为 从0到255）
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            // 根据上述描述创建渲染管线状态
            try rps = device?.makeRenderPipelineState(descriptor: rpld)
        } catch let error{
           fatalError("\(error)")
        }
    }

    override func draw(_ rect: CGRect) {
        // 确保currentDrawable和currentRenderPassDescriptor不是空
        if let drawable = currentDrawable, let rpd = currentRenderPassDescriptor {
            // colorAttachments 是一组纹理，用于保存绘图结果并将其显示在屏幕上。 我们目前只有一个这样的纹理, 数组的第一个元素（在索引0处）
            rpd.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
            // 存储来自命令编码器的翻译命令。 当缓冲区完成执行命令时，Metal会通知应用程序
            let commandBuffer = commandQueue!.makeCommandBuffer()
            // 将API命令转换为GPU硬件命令，render command encoder(渲染命令编码器，用于图形渲染)， 另外编码器：compute（用于数据并行处理）和blit（用于资源复制操作）
            // Render Command Encoder（RCE）为单个渲染过程生成硬件命令，这意味着将所有渲染发送到单个framebuffer(帧缓冲区对象)（一组目标）。 如果需要渲染另一个帧缓冲区（一组目标），则需要创建一个新的RCE。 RCE为graphics pipeline(图形管道)的vertex(顶点)和fragment(片段)指定状态
            let commandEncode = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd)
            // 让命令encoder(编码器)知道我们的三角形，设置渲染管线状态，设置顶点的缓冲区
            commandEncode?.setRenderPipelineState(rps!)
            commandEncode?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            // 绘制片元，用三角形方式绘制（每3个点组成一个片元）
            commandEncode?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            commandEncode?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }

}
