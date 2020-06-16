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
    
    private var metalLayer: CAEAGLLayer {
        return layer as! CAEAGLLayer
    }
    
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    private var eagContext: EAGLContext?
    
    private var program: GLuint = 0
    private var renderBuffer: GLuint = 0
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
        eagContext = EAGLContext(api: .openGLES2)
        self.metalLayer.frame = self.bounds
        self.metalLayer.isOpaque = true
        metalLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking : false,
                                               kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8]
        genBuffer()
        loadShader()
    }
    
    func genBuffer() {
        EAGLContext.setCurrent(self.eagContext)
        
        glGenFramebuffers(1, &self.frameBuffer)
        glGenRenderbuffers(1, &self.renderBuffer)
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.frameBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.renderBuffer)
        
        self.eagContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: self.metalLayer)
        
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), self.renderBuffer)
    }
    
    func loadShader() {
        if self.program > 0 {
            glDeleteProgram(self.program)
        }
        
        let vertexSources =
            "attribute vec3 position;" +
            "void main() {" +
            "  gl_Position = vec4(position, 1.0);" +
            "}"
        let fragmentSources =
            "precision mediump float;" +
            "void main() {" +
            "  gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);" +
            "}"
        let vertexShader = compilerShader(GLenum(GL_VERTEX_SHADER), vertexSources)
        let fragmentShader = compilerShader(GLenum(GL_FRAGMENT_SHADER), fragmentSources)
        
        self.program = glCreateProgram()
        
        glAttachShader(self.program, vertexShader)
        glAttachShader(self.program, fragmentShader)
        
        glBindAttribLocation(self.program, 3, ("position" as NSString).utf8String)
        
        glLinkProgram(self.program)
        
        var linkSuccess: GLint = 1
        glGetProgramiv(self.program, GLenum(GL_LINK_STATUS), &linkSuccess)
        
        if linkSuccess == GL_FALSE {
            var message = [GLchar](repeating: GLchar(0), count: 256)
            var len = GLsizei(0)
            glGetProgramInfoLog(self.program, 256, &len, &message)
            let log = String.init(utf8String: message)
            print("program link error is \(String(describing: log))")
        }
        
        glDeleteShader(vertexShader)
        glDeleteShader(fragmentShader)
    }

    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        render()
    }
    
    func render() {
        EAGLContext.setCurrent(self.eagContext)
        
        glUseProgram(self.program)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.frameBuffer)
        
        glClearColor(0, 0, 0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
        
        let positionLocaltion: GLuint = 3
//        let colorLocation: GLuint = 4
        
        let vertices:[GLfloat] =
            [-0.5, -0.5, 0.0,
             0.5, -0.5, 0.0,
             0.0, 0.5, 0.0]
        glVertexAttribPointer(positionLocaltion, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, vertices)
        glEnableVertexAttribArray(positionLocaltion)
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)
        
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
