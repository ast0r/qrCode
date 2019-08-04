//
//  ViewController.swift
//  Lesson11
//
//  Created by Pavel Ivanov on 4/12/19.
//  Copyright © 2019 Pavel Ivanov. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var qrCodeFrameArray : [UIView] = []
    
    
    //var qrCodeFrameView: UIView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        
        captureButton.layer.cornerRadius = captureButton.frame.size.width / 2
        captureButton.layer.borderWidth = 2
        captureButton.layer.borderColor = UIColor.red.cgColor
        captureButton.clipsToBounds = true
        captureButton.isHidden = false
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            
            print("Unable to access back camera!")
            return
        }
        
        //let videoInput: AVCaptureDeviceInput
        do {
         
           let videoInput = try AVCaptureDeviceInput(device: captureDevice)
            
            //Init the captureSession object
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = .high
            //Set the input device on the ca[ture session
            captureSession?.addInput(videoInput)
            
            //Get an instance of ACCapturePhotoOutput class
            stillImageOutput = AVCapturePhotoOutput()
            stillImageOutput.isHighResolutionCaptureEnabled = true
            
            captureSession.addOutput(stillImageOutput)
            
            //MARK: - recognize some object
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr , AVMetadataObject.ObjectType.face]
            
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer.connection?.videoOrientation = .portrait
            videoPreviewLayer.frame = view.layer.bounds
            previewView.layer.addSublayer(videoPreviewLayer)
            
            self.captureSession?.startRunning()
            
            messageLabel.isHidden = true
            
            //qrCodeFrameView = UIView()
            
            for _ in 0...3 {
                
                var qrFrame = UIView()
                qrFrame.layer.borderColor = UIColor.randomColor().cgColor
                qrFrame.layer.borderWidth = 2
                view.addSubview(qrFrame)
                view.bringSubviewToFront(qrFrame)
               
                
               /* if let qrCodeFrameView = qrCodeFrameView {
                    
                    qrCodeFrameView.layer.borderColor = UIColor.randomColor().cgColor
                    qrCodeFrameView.layer.borderWidth = 2
                    view.addSubview(qrCodeFrameView)
                    view.bringSubviewToFront(qrCodeFrameView)
                }
                */
                qrCodeFrameArray.append(qrFrame)
 
                
            }
            
           /* if let qrCodeFrameView = qrCodeFrameView {
            
                qrCodeFrameView.layer.borderColor = UIColor.randomColor().cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            } */
            
            
        } catch let error {
            print(" Error to unabled initialize back camera: \(error.localizedDescription)")
            return
        }
    }
    
    
    @IBAction func onTapTakePhote(_ sender: UIButton) {
        
       // guard let capturePhotoOutput = self.stillImageOutput else { return }
        
        let photoSettings = AVCapturePhotoSettings(format:  [AVVideoCodecKey: AVVideoCodecType.jpeg])
        
        
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        
        stillImageOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        let capturedImage = UIImage(data: imageData, scale: 1.0)
        if let image = capturedImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
    
   /* func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        guard error == nil ,
            let photoSampleBuffer = photoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }*/
        
        //guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
    
    
            
    
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if metadataObjects  == nil || metadataObjects.count == 0 {
            
            for item in qrCodeFrameArray {
                item.frame = CGRect.zero
                messageLabel.isHidden = true
            }
            
            return
        }
        
        /*for metaObj in metadataObjects {
            
            print("Metadata obj  \(metaObj.bounds)")
        }*/
        
       for (i,metaObj) in metadataObjects.enumerated() {
         
           print("Metadata obj  \(metaObj.bounds)")
        if i <= 4 {
        
            if let metadataObj = metaObj as? AVMetadataMachineReadableCodeObject{
                
                let barCodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObj)
                
                qrCodeFrameArray[i].frame = barCodeObject!.bounds                
                /*qrCodeFrameView?.frame = barCodeObject!.bounds*/
                
                if metadataObj.stringValue != nil {
                    messageLabel.backgroundColor = .white
                    messageLabel.isHidden = false
                    messageLabel.text = metadataObj.stringValue
                    debugPrint("Debug \(metadataObj.stringValue!)")
                }
            } else if let faceObj = metaObj as? AVMetadataFaceObject {
                
                let faceObject = self.videoPreviewLayer.transformedMetadataObject(for: faceObj)
                qrCodeFrameArray[i].frame = faceObject!.bounds
            }
         }
        }
        
       /* if let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
            let barCodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                messageLabel.backgroundColor = .white
                messageLabel.isHidden = false
                messageLabel.text = metadataObj.stringValue
                debugPrint(metadataObj.stringValue!)
            }
        } else if let faceObj = metadataObjects[0] as? AVMetadataFaceObject {
            
            let faceObject = self.videoPreviewLayer.transformedMetadataObject(for: faceObj)
            qrCodeFrameView?.frame = faceObject!.bounds
        }*/
        
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    
    static func randomColor() -> UIColor {
        
        return UIColor(
            red: .random(),
            green: .random(),
            blue: .random(),
            alpha: 1.0)
    }
}

