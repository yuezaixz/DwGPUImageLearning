//
//  BrightnessViewController.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/13.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import GPUImage

class BrightnessViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture: PictureInput!
    var filter: BrightnessAdjustment!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picture = PictureInput(image: UIImage(named: "fanqie.jpg")!)
        filter = BrightnessAdjustment()
        filter.brightness = 0.0
        
        picture --> filter --> renderView
        picture.processImage()
    }
    
    @IBAction func valChangeAction(_ sender: UISlider) {
        filter.brightness = sender.value
        picture.processImage()
    }

}
