//
//  ViewController.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/13.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture:PictureInput!
    var filter:SepiaToneFilter!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        picture = PictureInput(image:UIImage(named:"fanqie.jpg")!)
        filter = SepiaToneFilter()
        picture --> filter --> renderView
        picture.processImage()
    }
}

