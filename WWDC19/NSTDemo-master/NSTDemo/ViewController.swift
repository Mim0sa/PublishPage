//
//  ViewController.swift
//
//  Copyright (c) Alexis Creuzot (http://alexiscreuzot.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

class ViewController: UIViewController {
    
    typealias FilteringCompletion = ((UIImage?, Error?) -> ())
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var loader: UIActivityIndicatorView!
    @IBOutlet private var buttonHolderView: UIView!
    @IBOutlet private var applyButton: UIButton!
    @IBOutlet private var loaderWidthConstraint: NSLayoutConstraint!
    
    var imagePicker = UIImagePickerController()
    var isProcessing : Bool = false {
        didSet {
            self.applyButton.isEnabled = !isProcessing
            self.isProcessing ? self.loader.startAnimating() : self.loader.stopAnimating()
            self.loaderWidthConstraint.constant = self.isProcessing ? 20.0 : 0.0
            UIView.animate(withDuration: 0.3) {
                self.isProcessing
                    ? self.applyButton.setTitle("Processing...", for: .normal)
                    : self.applyButton.setTitle("Apply Style", for: .normal)
                self.view.layoutIfNeeded()
            }
        }
    }
    
    //MARK:- Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isProcessing = false
        self.applyButton.superview!.layer.cornerRadius = 4
    }
    
    //MARK: - Utils
    func showError(_ error: Error) {
        
        self.buttonHolderView.backgroundColor = UIColor(red: 220/255, green: 50/255, blue: 50/255, alpha: 1)
        self.applyButton.setTitle(error.localizedDescription, for: .normal)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Change `2.0` to the desired number of seconds.
            self.applyButton.setTitle("Apply Style", for: .normal)
            self.buttonHolderView.backgroundColor = UIColor(red: 5/255, green: 122/255, blue: 255/255, alpha: 1)
        }
    }
    
    //MARK:- CoreML
    
    func process(input: UIImage, completion: @escaping FilteringCompletion) {
        
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Initialize the NST model
        let model = STUdnieMLModel()
        
        // Next steps are pretty heavy, better process them on another thread
        DispatchQueue.global().async {

            // 1 - Resize our input image
            guard let inputImage = input.resize(to: CGSize(width: 480, height: 640)) else {
                completion(nil, NSTError.resizeError)
                return
            }

            // 2 - Transform our UIImage to a PixelBuffer of appropriate size
            guard let cvBufferInput = inputImage.pixelBuffer() else {
                completion(nil, NSTError.pixelBufferError)
                return
            }

            // 3 - Feed that PixelBuffer to the model (this is where the actual magic happens)
            guard let output = try? model.prediction(input1: cvBufferInput) else {
                completion(nil, NSTError.predictionError)
                return
            }

            // 4 - Transform PixelBuffer output to UIImage
            guard let outputImage = UIImage(pixelBuffer: output.output1) else {
                completion(nil, NSTError.pixelBufferError)
                return
            }

            // 5 - Resize result back to the original input size
            guard let finalImage = outputImage.resize(to: input.size) else {
                completion(nil, NSTError.resizeError)
                return
            }

            // 6 - Hand result to main thread
            DispatchQueue.main.async {
                
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                print("Time elapsed for NST process: \(timeElapsed) s.")
                
                completion(finalImage, nil)
            }
        }
    }
    
    //MARK:- Actions
    
    @IBAction func importFromLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .photoLibrary
            self.imagePicker.allowsEditing = false
            self.present(self.imagePicker, animated: true)
        } else {
            print("Photo Library not available")
        }
    }
    
    @IBAction func applyNST() {
        
        guard let image = self.imageView.image else {
            print("Select an image first")
            return
        }
        
        self.isProcessing = true
        self.process(input: image) { filteredImage, error in
            self.isProcessing = false
            if let filteredImage = filteredImage {
                self.imageView.image = filteredImage
            } else if let error = error {
                self.showError(error)
            } else {
                self.showError(NSTError.unknown)
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            self.imageView.image = pickedImage
            self.imageView.backgroundColor = .clear
        }
        self.dismiss(animated: true)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
