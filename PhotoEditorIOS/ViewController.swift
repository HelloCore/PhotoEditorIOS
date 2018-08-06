//
//  ViewController.swift
//  PhotoEditorIOS
//
//  Created by Akkharawat Chayapiwat on 8/6/18.
//  Copyright © 2018 Akkharawat Chayapiwat. All rights reserved.
//

import UIKit
import PhotoEditorSDK

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startBtnTap(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
}

extension ViewController: PhotoEditorViewDelegate {
    func photoEditorViewDidCancel() {
        print("Cancel")
    }
    
    func photoEditorViewDidEditImage(_ image: UIImage) {
        imageView.image = image
    }
}



extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        picker.dismiss(animated: true, completion: nil)
        
        let photoEditorVC = PhotoEditorManager.shared.initPhotoEditorVC(image: image, delegate: self)
        
        present(photoEditorVC, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
