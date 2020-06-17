//
//  GLDrawShapeView.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/17.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import OpenGLES

class GLDrawShapeView: UIView {
    
    // CALayer支持Open GL绘制Conents的子类。
    private var metalLayer: CAEAGLLayer {
        return layer as! CAEAGLLayer
    }
    
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    // 当前线程OpenGL ES状态机，也就是上下文
    private var eagContext: EAGLContext?
    
    // 挂载着色器的progarm
    private var program: GLuint = 0
    // 渲染过程的缓冲区，也叫帧缓冲区，是最后要展示的结果
    private var renderBuffer: GLuint = 0
    // 渲染缓存
    private var frameBuffer: GLuint = 0
    
    
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
        // 创建OpenGL ES2 的上下文
        eagContext = EAGLContext(api: .openGLES2)
        // 初始化OpenGL绘制Layer的一些属性
        self.metalLayer.frame = self.bounds
        self.metalLayer.isOpaque = true
        metalLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking : false,
                                               kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8]
        // 初始化一下renderBuffer和FrameBuffer
        genBuffer()
        // 初始化着色器程序
        loadShader()
    }
    
    func genBuffer() {
        EAGLContext.setCurrent(self.eagContext)
        
        // 生成缓冲区
        glGenFramebuffers(1, &self.frameBuffer)
        glGenRenderbuffers(1, &self.renderBuffer)
        
        // 绑定缓冲区
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.frameBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.renderBuffer)
        
        // 渲染层绑定
        self.eagContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: self.metalLayer)
        
        // 将渲染缓存绑定到帧缓存上
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), self.renderBuffer)
    }
    
    func loadShader() {
        // 已加载则删除
        if self.program > 0 {
            glDeleteProgram(self.program)
        }
        
        // 顶点着色器，简单的传递
        let vertexSources =
            "attribute vec3 position;" +
            "void main() {" +
            "  gl_Position = vec4(position, 1.0);" +
            "}"
        // 片段着色器，简单的用红色着色
        let fragmentSources =
            "precision mediump float;" +
            "void main() {" +
            "  gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);" +
            "}"
        // 编译两个着色器
        let vertexShader = compilerShader(GLenum(GL_VERTEX_SHADER), vertexSources)
        let fragmentShader = compilerShader(GLenum(GL_FRAGMENT_SHADER), fragmentSources)
        
        // 创建着色器程序标识
        self.program = glCreateProgram()
        
        // 绑定上相应着色器
        glAttachShader(self.program, vertexShader)
        glAttachShader(self.program, fragmentShader)
        
        // 设置索引和变量之间的对应关系，当前着色器传入的就是一个position，索引为3，与后面用到的glVertexAttribPointer相关联
        glBindAttribLocation(self.program, 3, ("position" as NSString).utf8String)
        
        // 将程序连接到OpenGL
        glLinkProgram(self.program)
        
        var linkSuccess: GLint = 1
        glGetProgramiv(self.program, GLenum(GL_LINK_STATUS), &linkSuccess)
        
        if linkSuccess == GL_FALSE {
            // 链接失败
            var message = [GLchar](repeating: GLchar(0), count: 256)
            var len = GLsizei(0)
            glGetProgramInfoLog(self.program, 256, &len, &message)
            let log = String.init(utf8String: message)
            print("program link error is \(String(describing: log))")
        }
        
        // 清除已经绑定了的着色器
        glDeleteShader(vertexShader)
        glDeleteShader(fragmentShader)
    }

    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        render()
    }
    
    func render() {
        // 设置上下文
        EAGLContext.setCurrent(self.eagContext)
        
        // 引入程序库
        glUseProgram(self.program)
        // 绑定帧缓冲区
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.frameBuffer)
        
        // 用黑色清除背景色，clear设置背景色会比较快，大概认为 clear 改的是 cache 里的值，并不会真得写到显存里，所以特别快。cache 和 shader 的执行单元离得近，显存和 shader 的执行单元离得远，能少走点路就少走点路。
        glClearColor(0, 0, 0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        // x，y 以像素为单位，指定了视口的左下角位置。
        // width，height 表示这个视口矩形的宽度和高度，根据窗口的实时变化重绘窗口
        glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
        
        // 这里只使用位置，不使用颜色变量。位置的索引为3
        let positionLocaltion: GLuint = 3
//        let colorLocation: GLuint = 4
        
        let vertices:[GLfloat] =
            [-0.5, -0.5, 0.0,
             0.5, -0.5, 0.0,
             0.0, 0.5, 0.0]
        // 在内存中采用交叉模式存储，向gpu传入顶点数据的方法
        // 第一个参数是索引，第二个参数是长度，后面是类型
        glVertexAttribPointer(positionLocaltion, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, vertices)
        glEnableVertexAttribArray(positionLocaltion)
        
        // 使用缓存的数据进行绘制
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)
        
        // 将绑定的渲染缓存呈现到屏幕上
        let finished = eagContext?.presentRenderbuffer(Int(GL_RENDERBUFFER)) ?? false
        print("finished is: \(finished)")
    }
    
    func compilerShader(_ shaderType: GLenum, _ sources: String) -> GLuint {
        let shader = glCreateShader(shaderType)
        var sourcePointer = (sources as NSString).utf8String
        var len = GLint((sources as NSString).length)
        glShaderSource(shader, 1, &sourcePointer, &len)
        
        glCompileShader(shader)
        
        var success: GLint = 1
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &success)
        
        if success == GL_FALSE {
            var message = [GLchar](repeating: GLchar(0), count: 256)
            var len = GLsizei(0)
            glGetShaderInfoLog(shader, 256, &len, &message)
            let log = String.init(utf8String: message)
            print("shader:\(shaderType) compile error is \(String(describing: log))")
        }
        
        return shader
    }
    
    func setupTexture(_ imageName: String) {
        guard let image = UIImage.init(named: imageName) else { return }
        guard let ref = image.cgImage else { return }
        
        let width = image.size.width
        let height = image.size.height
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(width * height) * 4)

        let context = CGContext.init(data: data, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(width) * 4, space: colorSpace, bitmapInfo: ref.bitmapInfo.rawValue)
        context?.translateBy(x: 0, y: height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.clear(rect)
        context?.draw(ref, in: rect)
        
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), data)
        free(data)
    }

    
}
