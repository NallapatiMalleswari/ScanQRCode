


//
//  ScannQR.swift
//  ScannQRCode
//
//  Created by Malleswari on 06/07/18.
//  Copyright © 2018 Malleswari. All rights reserved.
//

import AVFoundation
import UIKit
import CoreGraphics

public protocol QRScannerDelegate:class {
    func qrScanner(_ controller: UIViewController, scanDidComplete result: String)
    func qrScannerDidFail(_ controller: UIViewController,  error: String)
    func qrScannerDidCancel(_ controller: UIViewController)
    func qrScannerFromGalley(_controller: UIViewController,scanDidcomplete result: String)
    func qrCodeFromTextField(_controller: UIViewController,scanDidcomplete result: String)
}

class QRcodeScannerController: UIViewController,AVCaptureMetadataOutputObjectsDelegate{
    
    var squareView:SquareView?
    let movingView = UIView()
    var imagePicker = UIImagePickerController()
    
    
    public weak var delegate:QRScannerDelegate?
    
    //Adding Extra features
    public var cameraImage:UIImage?
    public var cancelImage:UIImage?
    public var flashOnImage:UIImage?
    public var flashOffImage:UIImage?
    public var galleryImage:UIImage?
    public var iphoneIcon:UIImage?
    public var qrcodeIcon:UIImage?
    
    //Default Properties
    let topSpace: CGFloat = 44.0
    let spaceFactor: CGFloat = 16.0
    var devicePosition: AVCaptureDevice.Position = .back
    var delCnt: Int = 0
    
    var flashButton: UIButton = UIButton()
    var qrCodeTextField = UITextField()
    var arrowButton = UIButton()
    var orLabel = UILabel()
    let cancelButton = UIButton()
    let lineView = UIView()
    let galleryButton = UIButton()
    var phoneImageView = UIImageView()
    var qrCodeImageView = UIImageView()
    
    ///This is for adding delay so user will get sufficient time for align QR within frame
    let delayCount = 15
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    ///Convinience init for adding extra images (camera, torch, cancel)
    convenience public init(cameraImage: UIImage?, cancelImage: UIImage?, flashOnImage: UIImage?, flashOffImage: UIImage?,galleryImage: UIImage?,iphoneIcon: UIImage?, qrcodeIcon: UIImage?) {
        self.init()
        self.cameraImage = cameraImage
        self.cancelImage = cancelImage
        self.flashOnImage = flashOnImage
        self.flashOffImage = flashOffImage
        self.galleryImage = galleryImage
        self.iphoneIcon = iphoneIcon
        self.qrcodeIcon = qrcodeIcon
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isViewDidload:Bool = true
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        imagePicker.delegate = self
        qrCodeTextField.delegate = self
        
        
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        delCnt = 0
        prepareQRScannerView(self.view)
        startScanningQRCode()
        
        movingView.backgroundColor = UIColor.blue
        view.addSubview(movingView)
        
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func prepareQRScannerView(_ view: UIView) {
        setupCaptureSession(devicePosition)
        addViedoPreviewLayer(view)
        addButtons(view)
        createCornerFrame()
    }
    
    //capture device
    var defaultDevice: AVCaptureDevice? = {
        if let device = AVCaptureDevice.default(for: .video){
            return device
        }
        return nil
    }()
    
    ///Initialise front CaptureDevice
    lazy var frontDevice: AVCaptureDevice? = {
        if #available(iOS 10, *) {
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                return device
            }
        } else {
            for device in AVCaptureDevice.devices(for: .video) {
                if device.position == .front {
                    return device
                }
            }
        }
        return nil
    }()
    
    //AVCaptureinput with default device
    
    lazy var defaultCaptureInput: AVCaptureInput? = {
        if let captureDevice = defaultDevice{
            do{
                return try AVCaptureDeviceInput(device: captureDevice)
            }catch let error {
                print("ERROR: \(error)")
            }
        }
        return nil
    }()
    
    ///Initialise AVCaptureInput with frontDevice
    lazy var frontCaptureInput: AVCaptureInput?  = {
        if let captureDevice = frontDevice {
            do {
                return try AVCaptureDeviceInput(device: captureDevice)
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }()
    
    lazy var dataOutput = AVCaptureMetadataOutput()
    
    ///Initialise capture session
    lazy var captureSession = AVCaptureSession()
    
    ///Initialise videoPreviewLayer with capture session
    lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        layer.cornerRadius = 0.0
        return layer
    }()
    
    
    
    
    /// Adds buttons to view which can we used as extra fearures
    private func addButtons(_ view: UIView) {
        let height: CGFloat = 44.0
        let width: CGFloat = 44.0
        
        var galleryButtonFrame: CGRect!
        var flashButtonFrame: CGRect!
        
        //Torch button
        if UIDevice().userInterfaceIdiom == .phone{
            switch UIScreen.main.nativeBounds.height{
            case 2436:
                print("iphoneX")
                flashButtonFrame = CGRect(x: 16, y: UIApplication.shared.statusBarFrame.height, width: width, height: height)
                galleryButtonFrame = CGRect(x: view.frame.width - (width+16), y: UIApplication.shared.statusBarFrame.height, width: width, height: height)
            default:
                print("unknown")
                let y = UIApplication.shared.statusBarFrame.height+10
                flashButtonFrame = CGRect(x: 16, y: y, width: width, height: height)
                galleryButtonFrame = CGRect(x: view.frame.width - (width+16), y: y, width: width, height: height)
            }
        }
        
        flashButton.frame = flashButtonFrame
        flashButton.tintColor = UIColor.white
        flashButton.layer.cornerRadius = height/2
        //flashButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        flashButton.contentMode = .scaleAspectFit
        flashButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
        if let flashOffImg = flashOffImage {
            flashButton.setImage(flashOffImg, for: .normal)
            view.addSubview(flashButton)
        }
        
        //QR code textfield
        qrCodeTextField.frame = CGRect(x: self.view.frame.midX - (self.view.frame.width/3), y: flashButton.bottom + 20, width: (self.view.bounds.width/3) * 2, height: self.view.frame.height * 0.05)
        qrCodeTextField.backgroundColor = UIColor.clear
        qrCodeTextField.textColor = .white
        qrCodeTextField.textAlignment = .center
        view.addSubview(qrCodeTextField)
        qrCodeTextField.attributedPlaceholder = NSAttributedString(string: "Enter QR code",
                                                                   attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        qrCodeTextField.returnKeyType = UIReturnKeyType.done
        
        
        arrowButton.frame = CGRect(x: qrCodeTextField.width+30, y: flashButton.bottom + 20, width: self.view.bounds.width/6, height: self.view.frame.height * 0.05)
        arrowButton.backgroundColor = UIColor.clear
        arrowButton.setImage(#imageLiteral(resourceName: "rightArrow"), for: .normal)
        view.addSubview(arrowButton)
        arrowButton.addTarget(self, action: #selector(VelidateQRcode), for: UIControlEvents.touchUpInside)
        
        
        
        lineView.frame = CGRect(x: qrCodeTextField.x, y: qrCodeTextField.bottom, width: qrCodeTextField.width, height: 1)
        lineView.backgroundColor = .white
        view.addSubview(lineView)
        
        
        orLabel.frame = CGRect(x: self.view.center.x - 15, y: lineView.bottom, width: self.view.bounds.width/6, height: self.view.frame.height * 0.05)
        self.view.addSubview(orLabel)
        orLabel.text = "Or"
        orLabel.textColor = UIColor.white
        
        //QRCode image
        let imageWidth = self.view.frame.width * 0.14
        qrCodeImageView.frame = CGRect(origin: CGPoint(x: self.view.frame.midX - (self.view.frame.width/11), y: orLabel.bottom+15), size: CGSize(width: imageWidth, height: imageWidth))
        qrCodeImageView.image = qrcodeIcon
        view.addSubview(qrCodeImageView)
        qrCodeImageView.contentMode = .center
        
        
        //GallaryImageButton
        
        galleryButton.frame = galleryButtonFrame
        galleryButton.setImage(galleryImage, for: .normal)
        
        galleryButton.contentMode = .scaleAspectFit
        galleryButton.addTarget(self, action: #selector(presentGalley), for: .touchUpInside)
        view.addSubview(galleryButton)
        
        
        //iphone Image
        phoneImageView.image = #imageLiteral(resourceName: "PhoneIcon")
        phoneImageView.frame = CGRect.init(origin: CGPoint(x: self.view.frame.midX - (self.view.frame.width/3), y: (orLabel.bottom)), size: CGSize(width: (self.view.frame.width * 0.16), height: (self.view.frame.height * 0.14)))
        view.addSubview(phoneImageView)
        
        UIView.animate(withDuration: 1, delay: 0.5, options: [.autoreverse,.repeat], animations: {
            self.phoneImageView.frame = CGRect.init(origin: CGPoint(x: self.view.frame.midX - (self.view.frame.width/10), y: (self.orLabel.bottom)), size: CGSize(width: self.view.frame.width * 0.16, height: self.view.frame.height * 0.14))
        }, completion: nil)
    }
    let maskLayer = CAShapeLayer()
    func addMaskLayerToVideoPreviewLayerAndAddText(rect: CGRect) {
        
        maskLayer.frame = view.bounds
        maskLayer.fillColor = UIColor(white: 0.0, alpha: 0.5).cgColor
        let path = UIBezierPath(rect: rect)
        path.append(UIBezierPath(rect: view.bounds))
        maskLayer.path = path.cgPath
        maskLayer.fillRule = kCAFillRuleEvenOdd
        
        view.layer.insertSublayer(maskLayer, above: videoPreviewLayer)
        
        let noteText = CATextLayer()
        noteText.fontSize = 18.0
        noteText.string = "Scan the QR code printed\n inside the ring case"
        noteText.alignmentMode = kCAAlignmentCenter
        noteText.contentsScale = UIScreen.main.scale
        noteText.frame = CGRect(x: spaceFactor, y: phoneImageView.bottom+15, width: view.frame.size.width - (2.0 * spaceFactor), height: 50)
        noteText.foregroundColor = UIColor.white.cgColor
        view.layer.insertSublayer(noteText, above: maskLayer)
        
    }
    
    ///Creates corner rectagle frame with black color(default color)
    
    func createCornerFrame() {
        
        let width: CGFloat =  self.view.bounds.width
        
        
        let rect = CGRect.init(origin: CGPoint.init(x: self.view.frame.midX - width/2.8, y: (phoneImageView.bottom+70)), size: CGSize.init(width: width * 0.7, height: width * 0.7))
        
        let squareFrameRect = CGRect(x: rect.origin.x+10, y: rect.origin.y+10, width: rect.width - 20, height: rect.height - 20)
        squareView = SquareView(frame: squareFrameRect)
        if let squareView = squareView {
            self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
            squareView.autoresizingMask = UIViewAutoresizing(rawValue: UInt(0.0))
            self.view.addSubview(squareView)
            qrCodeScanningIndicator(rect: rect)
            addMaskLayerToVideoPreviewLayerAndAddText(rect: rect)
        }
        
        
        //Cancel button
        var cancelButtonFrame: CGRect!
        
        if UIDevice().userInterfaceIdiom == .phone{
            switch UIScreen.main.nativeBounds.height{
            case 2436:
                print("iphoneX")
                cancelButtonFrame = CGRect(x: rect.origin.x, y: rect.origin.y+rect.height+40 , width: rect.width, height: 40)
            default:
                print("unknown")
                cancelButtonFrame = CGRect(x:rect.origin.x, y: rect.origin.y+rect.height+10, width: rect.width, height: 40)
            }
        }
        
        cancelButton.frame = cancelButtonFrame
        cancelButton.layer.cornerRadius = 21
        cancelButton.backgroundColor = UIColor.white
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor(red: 140/255, green:  219/255, blue: 251/255, alpha: 1), for: .normal)
        cancelButton.contentMode = .scaleAspectFit
        cancelButton.addTarget(self, action: #selector(dismissVC), for:.touchUpInside)
        view.addSubview(cancelButton)
    }
    
    
    //MARK:- button actions
    
    //Select Image
    @objc func presentGalley(){
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    //Toggle torch
    @objc func toggleTorch() {
        //If device postion is front then no need to torch
        if let currentInput = getCurrentInput() {
            if currentInput.device.position == .front {
                return
            }
        }
        
        guard  let defaultDevice = defaultDevice else {return}
        if defaultDevice.isTorchAvailable {
            do {
                try defaultDevice.lockForConfiguration()
                defaultDevice.torchMode = defaultDevice.torchMode == .on ? .off : .on
                if defaultDevice.torchMode == .on {
                    if let flashOnImage = flashOnImage {
                        self.flashButton.setImage(flashOnImage, for: .normal)
                    }
                } else {
                    if let flashOffImage = flashOffImage {
                        self.flashButton.setImage(flashOffImage, for: .normal)
                    }
                }
                
                defaultDevice.unlockForConfiguration()
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    //Switch camera
    @objc func switchCamera() {
        if let frontDeviceInput = frontCaptureInput {
            captureSession.beginConfiguration()
            if let currentInput = getCurrentInput() {
                captureSession.removeInput(currentInput)
                let newDeviceInput = (currentInput.device.position == .front) ? defaultCaptureInput : frontDeviceInput
                captureSession.addInput(newDeviceInput!)
            }
            captureSession.commitConfiguration()
        }
    }
    
    private func getCurrentInput() -> AVCaptureDeviceInput? {
        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            return currentInput
        }
        return nil
    }
    
    @objc func dismissVC() {
        self.dismiss(animated: true, completion: nil)
        delegate?.qrScannerDidCancel(self)
    }
    @objc func VelidateQRcode(){
        if let qrcode = qrCodeTextField.text, !qrcode.isEmpty{
            print("QRCode textfield")
            delegate?.qrCodeFromTextField(_controller: self, scanDidcomplete: qrcode)
        }else{
           //error
                
            }
        }
 
    
    //MARK: - Setup and start capturing session
    
    open func startScanningQRCode() {
        if captureSession.isRunning {
            return
        }
        captureSession.startRunning()
    }
    
    private func setupCaptureSession(_ devicePostion: AVCaptureDevice.Position) {
        if captureSession.isRunning {
            return
        }
        
        switch devicePosition {
        case .front:
            if let frontDeviceInput = frontCaptureInput {
                if !captureSession.canAddInput(frontDeviceInput) {
                    delegate?.qrScannerDidFail(self, error: "Failed to add Input")
                    self.dismiss(animated: true, completion: nil)
                    return
                }
                captureSession.addInput(frontDeviceInput)
            }
            break;
        case .back, .unspecified :
            if let defaultDeviceInput = defaultCaptureInput {
                if !captureSession.canAddInput(defaultDeviceInput) {
                    delegate?.qrScannerDidFail(self, error: "Failed to add Input")
                    self.dismiss(animated: true, completion: nil)
                    return
                }
                captureSession.addInput(defaultDeviceInput)
            }
            break
        }
        
        if !captureSession.canAddOutput(dataOutput) {
            delegate?.qrScannerDidFail(self, error: "Failed to add Output")
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        captureSession.addOutput(dataOutput)
        dataOutput.metadataObjectTypes = dataOutput.availableMetadataObjectTypes
        dataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    }
    
    ///Inserts layer to view
    private func addViedoPreviewLayer(_ view: UIView) {
        if #available(iOS 11.0, *) {
            videoPreviewLayer.frame = CGRect(x:view.bounds.origin.x, y: view.bounds.origin.y, width: view.bounds.size.width, height: view.bounds.size.height)
        } else {
            videoPreviewLayer.frame = CGRect(x:view.bounds.origin.x, y: view.bounds.origin.y, width: view.bounds.size.width, height: view.bounds.size.height)
        }
        view.layer.insertSublayer(videoPreviewLayer, at: 0)
        print("View is added first time)")
    }
    var isCompleteAnimation = true
    
    //Adding QRcode scanning indicator
    
    func qrCodeScanningIndicator(rect:CGRect){
        
        
        movingView.frame = CGRect.init(origin: CGPoint.init(x: rect.origin.x , y: rect.origin.y), size: CGSize.init(width: rect.width, height: 5))
        
        UIView.animate(withDuration: 0.8, delay: 0.0, options: [.autoreverse, .repeat], animations: {
            if self.isCompleteAnimation{
                self.isCompleteAnimation = false
                self.movingView.frame = CGRect.init(origin: CGPoint.init(x: rect.origin.x , y: rect.origin.y+rect.height), size: CGSize.init(width: rect.width, height: 5))
            }
        }) { (success) in
            self.isCompleteAnimation = true
        }
        
    }
    
    /// This method get called when Scanning gets complete
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        for data in metadataObjects {
            let transformed = videoPreviewLayer.transformedMetadataObject(for: data) as? AVMetadataMachineReadableCodeObject
            if let unwraped = transformed {
                if view.bounds.contains(unwraped.bounds) {
                    delCnt = delCnt + 1
                    if delCnt > delayCount {
                        if let unwrapedStringValue = unwraped.stringValue {
                            print("unwrapedStringValue: \(unwrapedStringValue)")
                            delegate?.qrScanner(self, scanDidComplete: unwrapedStringValue)
                        } else {
                            delegate?.qrScannerDidFail(self, error: "Empty string found")
                        }
                        captureSession.stopRunning()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
///Currently Scanner suppoerts only portrait mode.
///This makes sure orientation is portrait
extension QRcodeScannerController {
    ///Make orientations to portrait
    override public var shouldAutorotate: Bool {
        return false
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
}
extension QRcodeScannerController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}




