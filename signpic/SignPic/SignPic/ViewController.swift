//
//  ViewController.swift
//  SignPic
//
//  Created by André Nogueira on 26/11/2020.
//  Copyright © 2020 André Nogueira. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultsLabel: UILabel!
    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        self.launchCamera()
    }
    var button: UIButton?
    
    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "model_mob_epoch_3", ofType: "pt"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()

    private lazy var labels: [String] = {
        if let filePath = Bundle.main.path(forResource: "labels", ofType: "txt"),
            let labels = try? String(contentsOfFile: filePath) {
            return labels.components(separatedBy: .newlines)
        } else {
            fatalError("Can't find the text file!")
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "SignPic"
        
        let image = UIImage(named: "nothing.png")!
        imageView.image = image
        
        predictLabel(image: image)
    }
    
    func launchCamera()
    {
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
            
        }
        else{
            let alert  = UIAlertController(title: "Warning", message: "There's no camera.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func predictLabel(image: UIImage) {
        let resizedImage = image.resized(to: CGSize(width: 224, height: 224))
        guard var pixelBuffer = resizedImage.normalized() else {
            return
        }
        guard let outputs = module.predict(image: UnsafeMutableRawPointer(&pixelBuffer)) else {
            return
        }
        let sortedResults = zip(labels.indices, outputs).sorted { $0.1.floatValue > $1.1.floatValue }.prefix(3)
        var text = ""
        for result in sortedResults {
            text += "\(labels[result.0]) "
        }
        resultsLabel.text = text
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
            self.predictLabel(image: imageView.image!)
        }
     
        dismiss(animated: true, completion: nil)
    }
}
