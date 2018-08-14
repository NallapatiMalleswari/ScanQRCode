//
//  ViewController.swift
//  ScannQRCode
//
//  Created by Malleswari on 06/07/18.
//  Copyright © 2018 Malleswari. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func startScanQRcodeButtonAction(_ sender: UIButton) {
        let scanner = QRcodeScannerController(cameraImage: UIImage(named: "camera"), cancelImage: UIImage(named: "cancel"), flashOnImage: UIImage(named: "flash-on"), flashOffImage: UIImage(named:"flash-off"), galleryImage: UIImage(named:"gallery"), iphoneIcon: UIImage(named: "PhoneIcon"), qrcodeIcon: UIImage(named: "QRCodeImage"))
        scanner.delegate = self
        self.present(scanner, animated: true, completion: nil)
    }
    

}

extension ViewController: QRScannerDelegate {
    func qrCodeFromTextField(_controller: UIViewController, scanDidcomplete result: String) {
        print("result:\(result)")
        self.dismiss(animated: true, completion: nil)
    }
    
    func qrScanner(_ controller: UIViewController, scanDidComplete result: String) {
        print("result:\(result)")
        
    }
    
    func qrScannerDidFail(_ controller: UIViewController, error: String) {
        print("error:\(error)")
    }
    
    func qrScannerDidCancel(_ controller: UIViewController) {
        print("SwiftQRScanner did cancel")
    }
    func qrScannerFromGalley(_controller: UIViewController, scanDidcomplete result: String) {
        print("result OF scanning: \(result)")
        self.dismiss(animated: true, completion: nil)
    }
}

