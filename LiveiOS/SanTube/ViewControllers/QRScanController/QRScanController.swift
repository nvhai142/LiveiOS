//
//  QRScanController.swift
//  SanTube
//
//  Created by Dai Pham on 1/31/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import AVFoundation

class QRScanController: BaseController {

    // MARK: - private
    private func configView() {
        
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        
        for vw in vwRears {
            vw.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        }
        imvScan.image = #imageLiteral(resourceName: "scan").tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        view.bringSubview(toFront: vwContent)
    }

    fileprivate func found(code: String) {
        let ac = UIAlertController(title: "Found a QRCode", message: "Text is: \(code)", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: true)
        }))
        present(ac, animated: true)
    }
    
    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: true)
            }))
        present(ac, animated: true)
        captureSession = nil
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        configView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    deinit {
        captureSession = nil
        print("QRScanController delloc")
    }
    
    // MARK: - override
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK: - closures
    
    // MARK: - properties
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    // MARK: - oulet
    @IBOutlet weak var vwContent: UIView!
    @IBOutlet var vwRears: [UIView]!
    @IBOutlet weak var imvScan: UIImageView!
}

// MARK: - AVCatpure delegate
extension QRScanController:AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(_ output: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

    }
}
