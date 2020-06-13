//
//  DwFilterAdapter.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/13.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import GPUImage

protocol DwFiltable {
    
    func setupFilter(renderView: RenderView, imagePath: String)
    
    func processImage()
    
}

class DwFilterAdapter: DwFiltable {
    
    var filters: [BasicOperation]
    var picture: PictureInput?
    
    init(_ filters: [BasicOperation]) {
        self.filters = filters
    }
    
    func setupFilter(renderView: RenderView, imagePath: String) {
        picture = PictureInput(image: UIImage(named: "fanqie.jpg")!)
        
        for filter in filters {
            picture! --> filter
        }
        picture!.processImage()
    }
    
    func processImage() {
        picture?.processImage()
    }
    
    
}
