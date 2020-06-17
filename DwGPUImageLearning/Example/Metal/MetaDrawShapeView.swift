//
//  MetaDrawShapeView.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/16.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import Metal

class MetaDrawShapeView: UIView {

    /// Metal 提供给开发者与 GPU 交互的能力。而这能力，则需要依赖 MTLDevice 来实现。
    var device: MTLDevice?
    
    /// 渲染管线
    var pipelineState: MTLRenderPipelineState!
    
    // CAMetalLayer 类，使它的 content 是由 Metal 进行渲染的
    var metalLayer: CAMetalLayer {
        return layer as! CAMetalLayer
    }
    
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    
    
    // MARK: -  init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    // MARK: - private
    private func commonInit() {
        device = MTLCreateSystemDefaultDevice()
        
        // 从Metal文件中加载顶点着色器和片段着色器，本例比较简单，顶点着色器就是简单的传递着色器，片段着色器只是用红色着色
        let library = device?.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexDrawShapeShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentDrawShapeShader")
        
        // 渲染管线状态
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        // 创建渲染管线
        pipelineState = try! device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        render()
    }
    
    func render() {
        guard let drawable = metalLayer.nextDrawable() else {
            return
        }
        /// 渲染的指令属性
        ///
        /// texture：关联的纹理，即渲染目标。必须设置，不然内容不知道要渲染到哪里。不设置会报错：failed assertion `No rendertargets set in RenderPassDescriptor.'
        /// loadAction：决定前一次 texture 的内容需要清除、还是保留
        /// storeAction：决定这次渲染的内容需要存储、还是丢弃
        /// clearColor：当 loadAction 是 MTLLoadActionClear 时，则会使用对应的颜色来覆盖当前 texture（用某一色值逐像素写入）
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.48, 0.74, 0.92, 1)
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        /// 渲染的指令，Metal管理,提交指令
        let commandQueue = device?.makeCommandQueue()
        let commandBuffer = commandQueue?.makeCommandBuffer()
        /// 创建3D渲染编码器
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        ///
        /// 创建顶点数据，本例相对opengl例子的改进就是，颜色通过缓存数据传入
        let vertices = [
            DwVertex(position: [0.5, -0.5], color: [1,0,0,1]),
            DwVertex(position: [-0.5, -0.5], color: [1,0,0,1]),
            DwVertex(position: [0.0, 0.5], color: [1,0,0,1])
        ]
        // 创建渲染缓冲区
        let buffer = device?.makeBuffer(bytes: vertices, length: MemoryLayout<DwVertex>.size * 3, options: .cpuCacheModeWriteCombined)
        // 将数据设置到渲染编码器
        renderCommandEncoder?.setVertexBuffer(buffer, offset: 0, index: 0)
        
        
        // 设置渲染管线
        renderCommandEncoder?.setRenderPipelineState(pipelineState!)
        
        // 绘制三角形
        // 这里有个坑要注意下，必须先设置渲染管线后才能设置基础图元类型
        renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        renderCommandEncoder?.endEncoding()
        // 渲染缓冲区提交到显示
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
