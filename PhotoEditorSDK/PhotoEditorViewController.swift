//
//  PhotoEditorViewController.swift
//  PhotoEditorSDK
//
//  Created by Akkharawat Chayapiwat on 8/6/18.
//  Copyright © 2018 Akkharawat Chayapiwat. All rights reserved.
//

import UIKit

enum PhotoEditorState {
    case empty
    case draw
    case text
    case shape
}

public protocol PhotoEditorViewDelegate: class {
    func photoEditorViewDidCancel()
    func photoEditorViewDidEditImage(_ image: UIImage)
}

public class PhotoEditorViewController: UIViewController {
    
    public weak var delegate: PhotoEditorViewDelegate?
    
    @IBOutlet weak var topLeftToolbar: UIStackView!
    @IBOutlet weak var normalToolbar: UIStackView!
    @IBOutlet weak var editingToolbar: UIStackView!
    
    @IBOutlet weak var topScrollView: UIScrollView!
    
    @IBOutlet weak var canvasContainerView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var canvasImageView: UIImageView!
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var shapeButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var colorCollectionView: UICollectionView!
    @IBOutlet weak var lineWidthSlider: UISlider!
    
    var state: PhotoEditorState = .empty {
        didSet {
            editingToolbar.isHidden = state == .empty
            normalToolbar.isHidden = state != .empty
            topScrollView.isScrollEnabled = state == .empty
//            topScrollView.isUserInteractionEnabled = state == .empty
            topScrollView.pinchGestureRecognizer?.isEnabled = state == .empty
            topScrollView.panGestureRecognizer.isEnabled = state == .empty
            colorCollectionView.isHidden = state == .empty
            
            switch state {
            case .empty:
                lineWidthSlider.isHidden = true
                break
                
            case .draw:
                self.tempPaths = []
                undoButton.isHidden = false
                lineWidthSlider.isHidden = false
                break
                
            case .shape:
                undoButton.isHidden = true
                lineWidthSlider.isHidden = true
                break
            case .text:
                undoButton.isHidden = true
                lineWidthSlider.isHidden = true
                break
                
            }
        }
    }
    
    // Controls
    var lineWidth: CGFloat {
        return CGFloat(lineWidthSlider.value)
    }
    
    var drawingColor: UIColor = UIColor.black {
        didSet {
            if oldValue != drawingColor {
                if let oldIndex = ColorItems.allColors.index(of: oldValue),
                    let newIndex = ColorItems.allColors.index(of: drawingColor) {
                    colorCollectionView.reloadItems(at: [IndexPath(item: oldIndex, section: 0), IndexPath(item: newIndex, section: 0)])
                }
            }
        }
    }
    
    // Drawing
    var drawingPanGesture: UIPanGestureRecognizer!
    var currentPath: DrawingPath?
    var tempPaths: [DrawingPath]? {
        didSet {
            guard let tempPaths = tempPaths else { return }
            undoButton.isEnabled = tempPaths.count > 0
        }
    }
    var savedPaths = [DrawingPath]()
    
    var lastTouchPoint: CGPoint?
    
    var originalImage: UIImage?
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.image = originalImage
        self.state = .empty
        
        drawingPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrawingPanGesture(_:)))
        drawingPanGesture.delegate = self
        self.canvasImageView.addGestureRecognizer(drawingPanGesture)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func undoButtonTap(_ sender: Any) {
        if self.state == .draw {
            if let tempPaths = self.tempPaths,
                tempPaths.count > 0 {
                self.tempPaths?.removeLast()
            }
            self.renderCanvas()
        }
    }
    
    @IBAction func doneButtonTap(_ sender: Any) {
        switch state {
        case .empty:
            break
            
        case .draw:
            if let tempPaths = self.tempPaths {
                self.savedPaths.append(contentsOf: tempPaths)
            }
            self.currentPath = nil
            self.tempPaths = nil
            break
            
        case .shape:
            break
            
        case .text:
            break
            
        }
        self.state = .empty
    }
    
    @IBAction func shapeButtonTap(_ sender: Any) {
        self.state = .shape
    }
    
    @IBAction func drawButtonTap(_ sender: Any) {
        self.state = .draw
    }
    
    @IBAction func textButtonTap(_ sender: Any) {
        self.state = .text
    }
    
    @IBAction func backButtonTap(_ sender: Any) {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
            self.delegate?.photoEditorViewDidCancel()
        }else{
            self.dismiss(animated: true) { [weak self] in
                self?.delegate?.photoEditorViewDidCancel()
            }
        }
    }
    
    @IBAction func saveButtonTap(_ sender: Any) {
        
        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, imageView.isOpaque, 0.0)
        imageView.drawHierarchy(in: CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height), afterScreenUpdates: false)
        canvasImageView.drawHierarchy(in: CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height), afterScreenUpdates: false)
        let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let snapshotImageFromMyView = snapshotImageFromMyView {
            if self.navigationController != nil {
                self.navigationController?.popViewController(animated: true)
                self.delegate?.photoEditorViewDidEditImage(snapshotImageFromMyView)
            }else{
                self.dismiss(animated: true) { [weak self] in
                    self?.delegate?.photoEditorViewDidEditImage(snapshotImageFromMyView)
                }
            }
        }
    }
    
    
    
    
    @objc func handleDrawingPanGesture(_ gesture: UIPanGestureRecognizer) {
        if self.state == .draw {
            switch gesture.state {
            case .began:
                currentPath = DrawingPath(color: self.drawingColor.cgColor, lineWidth: self.lineWidth)
                tempPaths?.append(currentPath!)
                lastTouchPoint = gesture.location(in: self.canvasImageView)
                
            case .changed:
                guard let lastTouchPoint = lastTouchPoint else { return }
                let currentPoint = gesture.location(in: self.canvasImageView)
                
                self.drawLineFrom(lastTouchPoint, toPoint: currentPoint)
                self.lastTouchPoint = currentPoint
                
            case .possible: break
                
            case .cancelled, .ended, .failed:
                if currentPath?.isEmpty == true {
                    guard let lastTouchPoint = lastTouchPoint else { return }
                    let currentPoint = gesture.location(in: self.canvasImageView)
                    
                    self.drawLineFrom(lastTouchPoint, toPoint: currentPoint)
                }
            }
        }
    }
    
    
    func drawLineFrom(_ fromPoint: CGPoint, toPoint: CGPoint) {
        currentPath?.addLine(from: fromPoint, to: toPoint)
        
        UIGraphicsBeginImageContext(canvasImageView.frame.size)
        if let context = UIGraphicsGetCurrentContext(), let currentPath = currentPath {
            canvasImageView.layer.render(in: context)
            
            context.move(to: fromPoint)
            context.addLine(to: toPoint)
            
            context.setLineCap(currentPath.lineCap)
            context.setLineWidth(currentPath.lineWidth)
            context.setStrokeColor(currentPath.color)
            context.setBlendMode(currentPath.blendMode)
            
            context.strokePath()
            
            canvasImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
    }
    
    public func renderCanvas() {
        UIGraphicsBeginImageContext(canvasImageView.frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            self.savedPaths.forEach { $0.drawInContext(context) }
            self.tempPaths?.forEach { $0.drawInContext(context) }
            canvasImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
    }
    
}

extension PhotoEditorViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.canvasContainerView
    }
}

extension PhotoEditorViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ColorItems.allColors.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCollectionViewCell", for: indexPath) as! ColorCollectionViewCell
        let color = ColorItems.allColors[indexPath.item]
        cell.configureCellWithColor(color, isSelected: self.drawingColor == color)
        return cell
    }
}

extension PhotoEditorViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let color = ColorItems.allColors[indexPath.item]
        self.drawingColor = color
    }
}

extension PhotoEditorViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == drawingPanGesture {
            return self.state == .draw
        }
        return false
    }
    
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
}

