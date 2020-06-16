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

    //1. Metal 提供给开发者与 GPU 交互的能力。而这能力，则需要依赖 MTLDevice 来实现。
    /*
     一个 MTLDevice 对象代表一个可以执行指令的 GPU。
     MTLDevice 协议提供了查询设备功能、创建 Metal 其他对象等方法。
     */
    var device: MTLDevice?
    //2.渲染管线
    var pipelineState: MTLRenderPipelineState!
    
    
    // MARK: -  init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    // MARK: - rpivate
    private func commonInit() {
        device = MTLCreateSystemDefaultDevice()
        
        
        let library = device?.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexDrawShapeShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentDrawShapeShader")
        
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        pipelineState = try! device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    /*
     了解 Core Animation 的朋友一定知道，实际上负责渲染的是 CALayer，而 UIView 主要做内容的管理和事件的响应
     Core Animation 定义了 CAMetalLayer 类，它的 content 是由 Metal 进行渲染的
     */
    var metalLayer: CAMetalLayer {
        return layer as! CAMetalLayer
    }
    
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }

    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        render()
    }
    
    func render() {
        guard let drawable = metalLayer.nextDrawable() else {
            return
        }
        /// 渲染的指令
        /*
         texture：关联的纹理，即渲染目标。必须设置，不然内容不知道要渲染到哪里。不设置会报错：failed assertion `No rendertargets set in RenderPassDescriptor.'
         loadAction：决定前一次 texture 的内容需要清除、还是保留
         storeAction：决定这次渲染的内容需要存储、还是丢弃
         clearColor：当 loadAction 是 MTLLoadActionClear 时，则会使用对应的颜色来覆盖当前 texture（用某一色值逐像素写入）
         */
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.48, 0.74, 0.92, 1)
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        /// 渲染的指令，Metal管理,提交指令
        let commandQueue = device?.makeCommandQueue()
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        ///
        ///1.顶点数据
        let vertices = [
            DwVertex(position: [0.5, -0.5], color: [1,0,0,1]),
            DwVertex(position: [-0.5, -0.5], color: [1,0,0,1]),
            DwVertex(position: [0.0, 0.5], color: [1,0,0,1])
        ]
        let buffer = device?.makeBuffer(bytes: vertices, length: MemoryLayout<DwVertex>.size * 3, options: .cpuCacheModeWriteCombined)
        renderCommandEncoder?.setVertexBuffer(buffer, offset: 0, index: 0)
        
        
        //2.设置渲染管线
        renderCommandEncoder?.setRenderPipelineState(pipelineState!)
        
        //3.绘制三角形
        /*
         注意:必须先设置渲染管线后才能设置基础图元类型
         */
        renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        renderCommandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}