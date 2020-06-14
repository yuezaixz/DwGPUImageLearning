//
//  MetalDrawCircleViewController.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/14.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import MetalKit

class MetalDrawCircleViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("GPU is not supported") }
        
        let radius = UIScreen.main.bounds.width - 20 - 20
        let frame = CGRect(x: 20, y: 100, width: radius, height: radius)
        
        // 1、MetalKit是一个对Metal的封装，让我们可以更方便的使用Metal
        // MTKView是MetalKit的一个自定义视图，并提供了方法来加载纹理、使用Metal缓冲区
        // 以及与Model I/O的接口
        // MTKView在iOS平台是UIView的子类
        let view = MTKView(frame: frame, device: device)
        view.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)
        self.view.addSubview(view)
        
        // 2、Model I/O是集成Metal和SceneKit的一个库。它可以加载Blender、Maya等软件制作的3D模型
        // 本Sample中无需加载3D模型，而是要加载Model I/O基本3D形状（也称为图元）， 通常将图元视为一个立方体、一个球体、一个圆柱体或一个圆环。
        
        // 内存分配器
        let allocator = MTKMeshBufferAllocator(device: device)
        // MDLMesh 是 Model I/O 创建一个具有指定大小的球体在数据缓冲区的所有顶点信息
        let mdlMesh = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75], segments: [100, 100], inwardNormals: false, geometryType: .triangles, allocator: allocator)
        // 将MDLMesh转换成网格MTKMesh
        guard let mesh = try? MTKMesh(mesh: mdlMesh, device: device) else { return }
        
        // 创建一个命令队列
        guard let commandQueue = device.makeCommandQueue() else { fatalError("Could not create a command queue") }
        
        // 用多行字符串的形式创建一个运行在GPU上的着色程序，这是一个Metal着色语言是一个C++的子集
        // 程序包含了一个顶点着色器和片段着色器
        // 顶点着色器直接返回传入的坐标
        // 片段着色器直接返回红色
        let shader = """
        #include <metal_stdlib> using namespace metal;

        struct VertexIn { float4 position [[ attribute(0) ]]; };

        vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) { return vertex_in.position; }

        fragment float4 fragment_main() { return float4(1, 0, 0, 1); }
        """
        
        guard let library = try? device.makeLibrary(source: shader, options: nil) else { fatalError("Could not create a shader libray") }
        
        // 编译器会检查函数是否存在，并使它们可用于PipelineDescriptor
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        // 在Metal中是通过Pipeline State来告诉GPU是否需要工作，这样可以让GPU更高效
        
        // 而控制Pipeline State就是通过PipelineDescriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        // 定义像素格式为 32位的rgba形式
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        // 设置前面定义好的着色器函数
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        // 您还将向GPU描述如何使用顶点描述符在内存中布置顶点。
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        
        // MTLRenderPipelineDescriptor还有很多其他属性，但该Sample中我们只修改这些，其他使用默认值就好
        
        // 通过管道描述符创建管道状态
        // 实际使用中，可能会创建很多个管理状态，加载不同的着色器
        if let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor) {
            
            // 获取命令队列的命令缓冲区，他讲存储GPU将要运行的所有命令
            // MTKView提供了一个易用的渲染过程描述符，它保存了一个叫drawable的纹理
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { fatalError() }
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
            
            guard let submesh = mesh.submeshes.first else { fatalError() }
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: 0)
            
            renderEncoder.endEncoding()
            guard let drawable = view.currentDrawable else { fatalError() }
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

}
