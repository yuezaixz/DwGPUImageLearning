//
//  StillCameraToLibaryViewController.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/13.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import GPUImage
import Photos

class StillCameraToLibaryViewController: UIViewController {
    
    @IBOutlet var filterView: RenderView?
    
    let videoCamera: Camera?
    var blendImage: PictureInput?
        
    var filterOperation: FilterOperationInterface?
    @IBOutlet weak var saveToLibaryButton: UIButton!
    
    required init(coder aDecoder: NSCoder)
    {
        do {
            videoCamera = try Camera(sessionPreset:.vga640x480, location:.backFacing)
            videoCamera!.runBenchmark = true
            filterOperation = FilterOperation(
                filter:{SketchFilter()},
                listName:"Sketch",
                titleName:"Sketch",
                sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.5),
                sliderUpdateCallback: {(filter, sliderValue) in
                    filter.edgeStrength = sliderValue
                },
                filterOperationType:.singleInput
            )
        } catch {
            videoCamera = nil
            filterOperation = nil
            print("Couldn't initialize camera with error: \(error)")
        }

        super.init(coder: aDecoder)!
    }
    
    func configureView() {
        guard let videoCamera = videoCamera else {
            let errorAlertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: "Couldn't initialize camera", preferredStyle: .alert)
            errorAlertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil))
            self.present(errorAlertController, animated: true, completion: nil)
            return
        }
        if let currentFilterConfiguration = self.filterOperation {
            self.title = currentFilterConfiguration.titleName
            
            // Configure the filter chain, ending with the view
            if let view = self.filterView {
                switch currentFilterConfiguration.filterOperationType {
                case .singleInput:
                    videoCamera.addTarget(currentFilterConfiguration.filter)
                    currentFilterConfiguration.filter.addTarget(view)
                case .blend:
                    videoCamera.addTarget(currentFilterConfiguration.filter)
                    self.blendImage = PictureInput(imageName:blendImageName)
                    self.blendImage?.addTarget(currentFilterConfiguration.filter)
                    self.blendImage?.processImage()
                    currentFilterConfiguration.filter.addTarget(view)
                case let .custom(filterSetupFunction:setupFunction):
                    currentFilterConfiguration.configureCustomFilter(setupFunction(videoCamera, currentFilterConfiguration.filter, view))
                }
                
                videoCamera.startCapture()
            }
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }

    @IBAction func saveToLibaryAction(_ sender: Any) {
        if let currentFilterConfiguration = self.filterOperation {
            saveToLibaryButton.isEnabled = false
            
            let pictureOutput = PictureOutput()
            pictureOutput.encodedImageFormat = .jpeg
            pictureOutput.encodedImageAvailableCallback = { imageData in
                print(imageData)
                if let image = UIImage(data: imageData) {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { (isSuccess, error) in
                        if isSuccess {
                            print("保存成功")
                        }
                    }
                }
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        if let videoCamera = videoCamera {
            videoCamera.stopCapture()
            videoCamera.removeAllTargets()
            blendImage?.removeAllTargets()
        }
        
        super.viewWillDisappear(animated)
    }
}
