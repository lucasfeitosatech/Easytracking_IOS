//
//  QRCodeDecodeViewController.swift
//  Easytracking
//
//  Created by Lucas Freitas on 26/08/19.
//  Copyright © 2019 First Decision. All rights reserved.
//

import UIKit
import ZXingObjC
import Alamofire

class QRDecodeViewController: UIViewController {
    
    // MARK: Properties

    @IBOutlet weak var scanView: UIView!
    //@IBOutlet weak var resultLabel: UILabel?
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UILabel!
    
    fileprivate var capture: ZXCapture?
    
    fileprivate var isScanning: Bool?
    fileprivate var easyTracking:EasyTracking!
    fileprivate var id:String!
    fileprivate var binary:String!
    fileprivate var binaryRS:String!
    fileprivate var redu:String!
    fileprivate var binaryFinal:String!
    fileprivate var binaryDecodedOTP:[String.Element]!
    fileprivate var isFirstApplyOrientation: Bool?
    fileprivate var captureSizeTransform: CGAffineTransform?
    
    
    // MARK: Life Circles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirstApplyOrientation == true { return }
        isFirstApplyOrientation = true
        applyOrientation()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            // do nothing
        }) { [weak self] (context) in
            guard let weakSelf = self else { return }
            weakSelf.applyOrientation()
        }
    }
    
}

// MARK: Helpers
extension QRDecodeViewController {
    func setup() {
        isScanning = false
        isFirstApplyOrientation = false
        
        capture = ZXCapture()
        guard let _capture = capture else { return }
        _capture.camera = _capture.back()
        _capture.focusMode =  .continuousAutoFocus
        _capture.delegate = self
        
        self.view.layer.addSublayer(_capture.layer)
//        guard let _scanView = scanView, let _resultLabel = resultLabel else { return }
        self.view.bringSubviewToFront(scanView)
        self.view.bringSubviewToFront(topView)
        self.view.bringSubviewToFront(bottomView)
    }
    
    func applyOrientation() {
        let orientation = UIApplication.shared.statusBarOrientation
        var captureRotation: Double
        var scanRectRotation: Double
        
        switch orientation {
        case .portrait:
            captureRotation = 0
            scanRectRotation = 90
            break
            
        case .landscapeLeft:
            captureRotation = 90
            scanRectRotation = 180
            break
            
        case .landscapeRight:
            captureRotation = 270
            scanRectRotation = 0
            break
            
        case .portraitUpsideDown:
            captureRotation = 180
            scanRectRotation = 270
            break
            
        default:
            captureRotation = 0
            scanRectRotation = 90
            break
        }
        
        applyRectOfInterest(orientation: orientation)
        
        let angleRadius = captureRotation / 180.0 * Double.pi
        let captureTranform = CGAffineTransform(rotationAngle: CGFloat(angleRadius))
        
        capture?.transform = captureTranform
        capture?.rotation = CGFloat(scanRectRotation)
        capture?.layer.frame = view.frame
    }
    
    func applyRectOfInterest(orientation: UIInterfaceOrientation) {
        guard var transformedVideoRect = scanView?.frame,
            let cameraSessionPreset = capture?.sessionPreset
            else { return }
        
        var scaleVideoX, scaleVideoY: CGFloat
        var videoHeight, videoWidth: CGFloat
        
        // Currently support only for 1920x1080 || 1280x720
        if cameraSessionPreset == AVCaptureSession.Preset.hd1920x1080.rawValue {
            videoHeight = 1080.0
            videoWidth = 1920.0
        } else {
            videoHeight = 720.0
            videoWidth = 1280.0
        }
        
        if orientation == UIInterfaceOrientation.portrait {
            scaleVideoX = self.view.frame.width / videoHeight
            scaleVideoY = self.view.frame.height / videoWidth
            
            // Convert CGPoint under portrait mode to map with orientation of image
            // because the image will be cropped before rotate
            // reference: https://github.com/TheLevelUp/ZXingObjC/issues/222
            let realX = transformedVideoRect.origin.y;
            let realY = self.view.frame.size.width - transformedVideoRect.size.width - transformedVideoRect.origin.x;
            let realWidth = transformedVideoRect.size.height;
            let realHeight = transformedVideoRect.size.width;
            transformedVideoRect = CGRect(x: realX, y: realY, width: realWidth, height: realHeight);
            
        } else {
            scaleVideoX = self.view.frame.width / videoWidth
            scaleVideoY = self.view.frame.height / videoHeight
        }
        
        captureSizeTransform = CGAffineTransform(scaleX: 1.0/scaleVideoX, y: 1.0/scaleVideoY)
        guard let _captureSizeTransform = captureSizeTransform else { return }
        let transformRect = transformedVideoRect.applying(_captureSizeTransform)
        capture?.scanRect = transformRect
    }
    
    func barcodeFormatToString(format: ZXBarcodeFormat) -> String {
        switch (format) {
        case kBarcodeFormatAztec:
            return "Aztec"
            
        case kBarcodeFormatCodabar:
            return "CODABAR"
            
        case kBarcodeFormatCode39:
            return "Code 39"
            
        case kBarcodeFormatCode93:
            return "Code 93"
            
        case kBarcodeFormatCode128:
            return "Code 128"
            
        case kBarcodeFormatDataMatrix:
            return "Data Matrix"
            
        case kBarcodeFormatEan8:
            return "EAN-8"
            
        case kBarcodeFormatEan13:
            return "EAN-13"
            
        case kBarcodeFormatITF:
            return "ITF"
            
        case kBarcodeFormatPDF417:
            return "PDF417"
            
        case kBarcodeFormatQRCode:
            return "QR Code"
            
        case kBarcodeFormatRSS14:
            return "RSS 14"
            
        case kBarcodeFormatRSSExpanded:
            return "RSS Expanded"
            
        case kBarcodeFormatUPCA:
            return "UPCA"
            
        case kBarcodeFormatUPCE:
            return "UPCE"
            
        case kBarcodeFormatUPCEANExtension:
            return "UPC/EAN extension"
            
        default:
            return "Unknown"
        }
    }
    func getId(from rawBytes:[UInt8]) -> String {
        
        var hex = ""
        for i in 2...33 {
            let n = rawBytes[i]
            hex += String(format:"%02X", n)
            //print(hex)
            
        }
        
        //print(hex.lowercased())
        return hex.lowercased()
    }
    
    func getBinary(from rawBytes:[UInt8]) -> String {
        
        var binary = ""
        for i in 34...rawBytes.count - 1 {
            let b = rawBytes[i]
            var bits = String(b,radix: 2)
            bits = bits.padding(toLength: 8, withPad: "0", startingAt: 0)
            print("b: \(b) + bits: \(bits)")
            binary += bits
        }
        print(binary.count)
        binary.removeLast(easyTracking.padQR)
        print(binary.count)
        return binary
    }
    
    func downLoadRedundancy(from id:String) {
        
        let urlString = "http://lucasfeitosa.online/red/\(id).red"
        Alamofire.request(urlString).responseData { response in
            
            switch response.result {
            case let .success(value):
                print(value)
                let infoRS = Array(value)
                self.decode2bitsInfo(from: infoRS)
                self.join2bitsInfoAnd6bitsInfo()
                self.decodeOTPBits()
                self.decodeMessage()
                
                break
            case let .failure(error):
                print(error)
                //print(error)
                break
                
            }
        }
        
    }
    
    func decode2bitsInfo(from info:[UInt8]){
        let gf = ZXGenericGF(primitive: 285, size: 256, b: 0)
        let decoder = ZXReedSolomonDecoder(field: gf)
        let data:ZXIntArray = ZXIntArray.init(length: UInt32(easyTracking.n))
        redu = ""
        var j = 0
        for i in easyTracking.k...easyTracking.n - 1 {
            let b = info[j]
            var bits = String(b,radix: 2)
            bits = bits.padding(toLength: 8, withPad: "0", startingAt: 0)
            print("b: \(b) + bits: \(bits)")
            redu += bits
            data.array[i] = Int32(info[j])
            j+=1
        }
        do {
            try decoder?.decode(data, twoS: Int32(2*easyTracking.k))
            
        } catch let error {
            print(error.localizedDescription)
        }
        binaryRS = ""
        for i in 0...easyTracking.k - 1 {
            let b = data.array[i]
            var bits = String(b,radix: 2)
            bits = bits.padding(toLength: 8, withPad: "0", startingAt: 0)
            print("b: \(b) + bits: \(bits)")
            binaryRS += bits
        }
        binaryRS.removeLast(easyTracking.padRS)
    
    }
    
    func join2bitsInfoAnd6bitsInfo() {
        
        
        binaryFinal = ""
        var cont = 0;
        var cont2 = 0;
        var cont3 = 0;
        for _ in 0...(8*easyTracking.y) - 1 {
            if (cont < 2) {
                let index = binaryRS.index(binaryRS.startIndex, offsetBy: cont2)
                binaryFinal += String(binaryRS[index])
                cont2+=1
            } else if (cont < 9) {
                let index = binary.index(binary.startIndex, offsetBy: cont3)
                binaryFinal += String(binary[index])
                cont3+=1;
            }
            cont+=1;
            if (cont == 8) {
                cont = 0;
            }
        }
        
    }
    
    func decodeOTPBits() {
        
        var redu = Array(self.redu)
        var binaryFinal = Array(self.binaryFinal)
        var cont2 = 0;
        for i in 0...easyTracking.y {
            let pos1 = 8 * i + 2;
            let xor1 = (String(binaryFinal[pos1]) as NSString).integerValue ^ (String(redu[cont2]) as NSString).integerValue
            binaryFinal[pos1] = Character.init(String(xor1))
            cont2+=1;
         
            let pos2 = 8 * i + 3;
            let xor2 = (String(binaryFinal[pos2]) as NSString).integerValue ^ (String(redu[cont2]) as NSString).integerValue
            binaryFinal[pos2] = Character.init(String(xor2))
            cont2+=1;
          
            let pos3 = 8 * i + 4;
            let xor3 = (String(binaryFinal[pos3]) as NSString).integerValue ^ (String(redu[cont2]) as NSString).integerValue
            binaryFinal[pos3] = Character.init(String(xor3))
            cont2+=1;
          
            let pos4 = 8 * i + 5;
            let xor4 = (String(binaryFinal[pos4]) as NSString).integerValue ^ (String(redu[cont2]) as NSString).integerValue
            binaryFinal[pos4] = Character.init(String(xor4))
            cont2+=1;
          
        }
        self.binaryDecodedOTP = binaryFinal
    }
    
    func decodeMessage() {
        
        
        var bits7 = ""
        var infoFinal = ""
        var cont = 0;
        for i in 0 ... binaryDecodedOTP.count - 1 {
            
            bits7 += String(binaryDecodedOTP[i])
            cont+=1;
            if cont == 7 {
                let number = strtoul(bits7, nil, 2)
                let c = String(describing: UnicodeScalar(UInt8(number)))
                infoFinal += c
                bits7 = ""
                cont = 0
            }
        }
        print(infoFinal)
        
    }
    
}

// MARK: ZXCaptureDelegate
extension QRDecodeViewController: ZXCaptureDelegate {
    func captureCameraIsReady(_ capture: ZXCapture!) {
        isScanning = true
    }
    
    func captureResult(_ capture: ZXCapture!, result: ZXResult!) {
        guard let _result = result, isScanning == true else { return }
        
        capture?.stop()
        isScanning = false
        guard let rawData = _result.text.data(using: String.Encoding.macOSRoman) else {
            return
        }
        let rawBytes = Array(rawData)
        let x = rawBytes[0] + rawBytes[1]
        self.easyTracking = EasyTracking(from: Int(x))
        self.id = getId(from:rawBytes)
        self.binary = getBinary(from:rawBytes)
        downLoadRedundancy(from: id)
        
        
        
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.isScanning = true
            weakSelf.capture?.start()
        }
    }
    
}


