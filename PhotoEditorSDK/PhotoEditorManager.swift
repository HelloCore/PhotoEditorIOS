//
//  PhotoEditorManager.swift
//  PhotoEditorSDK
//
//  Created by Akkharawat Chayapiwat on 8/6/18.
//  Copyright © 2018 Akkharawat Chayapiwat. All rights reserved.
//

import Foundation

public class PhotoEditorManager {
    
    public static let shared = PhotoEditorManager()
    
    public func initPhotoEditorVC(image: UIImage, delegate: PhotoEditorViewDelegate) -> PhotoEditorViewController {
        let bundle = Bundle(for: PhotoEditorManager.self)
        let storyboard = UIStoryboard(name: "PhotoEditor", bundle: bundle)
        let vc = storyboard.instantiateViewController(withIdentifier: "PhotoEditorViewController") as! PhotoEditorViewController
        vc.originalImage = image
        vc.delegate = delegate
        return vc
    }
    
}
