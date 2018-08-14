//
//  SelectQRcodeFromGallery.swift
//  QrcodeDemo
//
//  Created by Malleswari on 11/07/18.
//  Copyright © 2018 Malleswari. All rights reserved.
//

import Foundation
import UIKit

extension QRcodeScannerController: UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let qrCodeImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            print("Image: \(qrCodeImage)")
            guard let detector:CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]) else{return}
            let ciImage:CIImage = CIImage(image: qrCodeImage)!
            var qrCodeLink = ""
            let features = detector.features(in: ciImage)
            for feature in features as! [CIQRCodeFeature] {
                qrCodeLink += feature.messageString!
            }
            if qrCodeLink == ""{
                print("nothing")
            }else{
                print("message: \(qrCodeLink)")
                delegate?.qrScannerFromGalley(_controller: self, scanDidcomplete: qrCodeLink)
            }
            
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }

}


