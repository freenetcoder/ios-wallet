//
// WalletQRCodeScannerViewController.swift
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


import UIKit
import AVFoundation
import Loaf

protocol WalletQRCodeScannerViewControllerDelegate: AnyObject {
    func didScanQRCode(value:String, amount:String?)
}

class WalletQRCodeScannerViewController: BaseViewController {

    weak var delegate: WalletQRCodeScannerViewControllerDelegate?
    
    @IBOutlet private weak var scannerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private var offset:CGFloat = 180
    private var scannedValue:String = ""
    public var isBotScanner = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Scan QR code"
        
        if Device.screenType == .iPhones_6 || Device.screenType == .iPhones_5
            || Device.screenType == .iPhones_Plus
        {
           offset = 140
        }
        
        scannerView.frame = CGRect(x: 0, y: offset, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height-offset)
        
        if isBotScanner {
            titleLabel.text = "Scan telegram QR code"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkCameraPermissions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    private func initSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .aztec, .code128]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = scannerView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        scannerView.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    private func detectQRCode(_ image: UIImage?) -> [CIFeature]? {
//        if let features = detectQRCode(#imageLiteral(resourceName: "qrcode")), !features.isEmpty{
//            for case let row as CIQRCodeFeature in features{
//                print(row.messageString ?? "nope")
//            }
//        }
        
        if let image = image, let ciImage = CIImage.init(image: image){
            var options: [String: Any]
            let context = CIContext()
            options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
            if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)){
                options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
            }else {
                options = [CIDetectorImageOrientation: 1]
            }
            let features = qrDetector?.features(in: ciImage, options: options)
            return features
            
        }
        return nil
    }

}

//MARK: - V3QRCodeReaderDelegate

extension WalletQRCodeScannerViewController : AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            getBarCodeData(code: stringValue)
        }

    }
    
    private func showError() {
        let loaf = Loaf("QR code cannot be recognized recognized. Please try again.", state: .custom(.init(backgroundColor: UIColor.black.withAlphaComponent(0.8), icon: nil)), sender: self)
        loaf.show(Loaf.Duration.average) { (_ ) in
            self.scannedValue = ""
        }
    }
    
    private func getBarCodeData(code: String) {
        
        if (scannedValue.isEmpty)
        {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            scannedValue = code;
            
            if isBotScanner {
                do {
                    if let json = try JSONSerialization.jsonObject(with: scannedValue.data(using: .utf8)!, options: .mutableContainers) as? [String: Any] {
                        print(json)
                        
                        if (json["_id"] as? u_quad_t) != nil {
                            navigationController?.popViewController(animated: true)
                            
                            delegate?.didScanQRCode(value: scannedValue, amount: nil)
                        }
                    }
                    else{
                        self.showError()
                    }
                } catch _ {
                    self.showError()
                }
            }
            else{
                var address = code
                var amount:String?
                
                if(address.hasPrefix("beam:"))
                {
                    let removePrefix = address.replacingOccurrences(of: "beam:", with: "")
                    
                    if (removePrefix.contains("?")) {
                        let url = URL(string: removePrefix)
                        let params = url?.queryParameters
                        
                        if let a = params?["amount"] {
                            amount = a
                        }
                        
                        if let index = removePrefix.firstIndex(of: "?") {
                            address = String(removePrefix[..<index])
                        }
                    }
                    else {
                       address = removePrefix
                    }
                }
                
                if (!AppModel.sharedManager().isValidAddress(address))
                {
                    self.showError()
                }
                else{
                    navigationController?.popViewController(animated: true)
                    
                    delegate?.didScanQRCode(value: address, amount: amount)
                }
            }
        }
    }
}


//MARK: - Permissions

extension WalletQRCodeScannerViewController {
    
    private func checkCameraPermissions() {
        let authStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        
        if(authStatus == .authorized) {
            initSession()
        }
        else if(authStatus == .notDetermined) {

            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                DispatchQueue.main.async {
                    if granted {
                        self.initSession()
                    }
                    else{
                        self.camDenied()
                    }
                }
            }
        }
        else if (authStatus == .restricted) {
            self.alert(message: "You've been restricted from using the camera on this device. Without camera access this feature won't work. Please contact the device owner so they can give you access")
        }
        else {
            self.camDenied()
        }
    }
    
    private func camDenied() {
        let message = "It looks like your privacy settings are preventing us from accessing your camera to do qr code scanning. You can fix this by doing the following:\n\n1. Touch the Go button below to open the Settings app.\n\n2. Turn the Camera on.\n\n3. Open this app and try again."
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: { (_ ) in
                 self.navigationController?.popViewController(animated: true)
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.navigationController?.popViewController(animated: true)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(openAction)

        self.present(alertController, animated: true, completion: nil)
    }
}
