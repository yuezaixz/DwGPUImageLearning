//
//  InnerFilterDisplayViewController.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/13.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import GPUImage

class InnerFilterDisplayViewController: UIViewController {
    
    var filterOperation: FilterOperationInterface?
    @IBOutlet var filterSlider: UISlider?
    
    @IBOutlet weak var renderView: RenderView!

    var picture: PictureInput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picture = PictureInput(image: UIImage(named: "fanqie.jpg")!)
        if let currentFilterConfiguration = self.filterOperation {
            self.title = currentFilterConfiguration.titleName
            picture.addTarget(currentFilterConfiguration.filter)
            currentFilterConfiguration.filter.addTarget(renderView)
            
//            picture.processImage()
            if let slider = self.filterSlider {
                switch currentFilterConfiguration.sliderConfiguration {
                case .disabled:
                    slider.isHidden = true
                case let .enabled(minimumValue, maximumValue, initialValue):
                    slider.minimumValue = minimumValue
                    slider.maximumValue = maximumValue
                    slider.value = initialValue
                    slider.isHidden = false
                    self.valChangeAction(slider)
                }
            }
        }
        
    }
    
    @IBAction func valChangeAction(_ sender: UISlider) {
        if let currentFilterConfiguration = self.filterOperation {
            switch (currentFilterConfiguration.sliderConfiguration) {
                case .enabled(_, _, _): currentFilterConfiguration.updateBasedOnSliderValue(Float(sender.value))
                case .disabled: break
            }
        }
        picture.processImage()
    }
    
}
