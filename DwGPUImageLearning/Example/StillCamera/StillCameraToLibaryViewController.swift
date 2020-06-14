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
    @IBOutlet weak var saveImageView: UIImageView!
    
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
        videoCamera.delegate = self
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
        if let image = lastImg {
            saveImageView.image = image
            
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            
//            PhotoAlbumUtil.saveImageInAlbum(image: image, albumName: "GPUImage") { (result) in
//                switch result{
//                case .success:
//                    print("保存成功")
//                case .denied:
//                    print("被拒绝")
//                case .error:
//                    print("保存错误")
//                }
//            }
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            print("Saved!")
//            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
//            ac.addAction(UIAlertAction(title: "OK", style: .default))
//            present(ac, animated: true)
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
    
    private var lastImg: UIImage?
}

extension StillCameraToLibaryViewController: CameraDelegate {
    func didCaptureBuffer(_ sampleBuffer: CMSampleBuffer) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))!
            let img = CIImage(cvPixelBuffer: pixelBuffer, options: attachments as? [CIImageOption: Any])
            lastImg = UIImage(ciImage: img)
        }
    }
    
}
