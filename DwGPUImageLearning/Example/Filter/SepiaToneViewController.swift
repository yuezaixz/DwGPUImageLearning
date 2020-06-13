//
//  ViewController.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/13.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import GPUImage

class SepiaToneViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture:PictureInput!
    var filter:SepiaToneFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picture = PictureInput(image:UIImage(named:"fanqie.jpg")!)
        filter = SepiaToneFilter()
        picture --> filter --> renderView
        picture.processImage()
    }
    
    @IBAction func valChangeAction(_ sender: UISlider) {
        filter.intensity = sender.value
        picture.processImage()
    }
    
}

