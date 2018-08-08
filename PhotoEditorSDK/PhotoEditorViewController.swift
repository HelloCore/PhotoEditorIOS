//
//  PhotoEditorViewController.swift
//  PhotoEditorSDK
//
//  Created by Akkharawat Chayapiwat on 8/6/18.
//  Copyright © 2018 Akkharawat Chayapiwat. All rights reserved.
//

import UIKit

enum PhotoEditorMode {
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
    @IBOutlet weak var clearButton: UIButton!
    
    @IBOutlet weak var colorCollectionView: UICollectionView!
    @IBOutlet weak var lineWidthSlider: UISlider!
    
    @IBOutlet weak var bottomToolbar: UIView!
    @IBOutlet weak var textSizeSlider: UISlider!
    
    var originalImage: UIImage?
    
    var mode: PhotoEditorMode = .empty {
        didSet {
            editingToolbar.isHidden = mode == .empty
            saveButton.isHidden = mode != .empty
            clearButton.isHidden = mode != .empty
            normalToolbar.isHidden = mode != .empty
            topScrollView.isScrollEnabled = mode == .empty
            topScrollView.pinchGestureRecognizer?.isEnabled = mode == .empty
            topScrollView.panGestureRecognizer.isEnabled = mode == .empty
            colorCollectionView.isHidden = mode == .empty
            
            switch mode {
            case .empty:
                lineWidthSlider.isHidden = true
                textSizeSlider.isHidden = true
                break
                
            case .draw:
                self.tempPaths = []
                textSizeSlider.isHidden = true
                undoButton.isHidden = false
                lineWidthSlider.isHidden = false
                break
                
            case .shape:
                textSizeSlider.isHidden = true
                undoButton.isHidden = true
                lineWidthSlider.isHidden = true
                break
            case .text:
                textSizeSlider.isHidden = false
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
                if let textView = currentTextView {
                    textView.textColor = drawingColor
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
    
    // Text
    var textViewList = [UITextView]()
    var textGestureList = [UIPanGestureRecognizer]()
    var currentTextView: UITextView?
    var currentTextTransform: CGAffineTransform?
    
    var keyboardTapGesture: UITapGestureRecognizer!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        

        self.imageView.image = originalImage
        self.mode = .empty
        
        drawingPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrawingPanGesture(_:)))
        drawingPanGesture.delegate = self
        self.canvasImageView.addGestureRecognizer(drawingPanGesture)
        
        keyboardTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleKeyboardTapGesture(_:)))
        keyboardTapGesture.delegate = self
        self.view.addGestureRecognizer(keyboardTapGesture)
        // Do any additional setup after loading the view.
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // MARK: - Button
    @IBAction func undoButtonTap(_ sender: Any) {
        if self.mode == .draw {
            if let tempPaths = self.tempPaths,
                tempPaths.count > 0 {
                self.tempPaths?.removeLast()
            }
            self.renderCanvas()
        }
    }
    
    @IBAction func doneButtonTap(_ sender: Any) {
        switch mode {
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
            if let textView = self.currentTextView {
                textView.resignFirstResponder()
            }
            self.currentTextView = nil
            break
            
        }
        self.mode = .empty
    }
    
    @IBAction func shapeButtonTap(_ sender: Any) {
        self.mode = .shape
    }
    
    @IBAction func drawButtonTap(_ sender: Any) {
        self.mode = .draw
    }
    
    @IBAction func textButtonTap(_ sender: Any) {
        self.mode = .text
        
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100))
        textView.text = "Text"
        textView.textColor = self.drawingColor
        
        textView.layer.borderColor = UIColor.black.cgColor
        
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.autocorrectionType = .no
        textView.textAlignment = .center
        textView.backgroundColor = UIColor.clear
        
        self.canvasImageView.addSubview(textView)
        
        let size = textView.sizeThatFits(CGSize(width: canvasImageView.frame.size.width, height: 100))
        let newFrame = CGRect(x: (canvasImageView.frame.size.width - size.width) / 2,
                                y: canvasImageView.frame.origin.y + 50 ,
                                width: size.width,
                                height: size.height)
        
        textView.frame = newFrame
        
        let textPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTextPanGesture(_:)))
        textPanGesture.delegate = self
        textView.addGestureRecognizer(textPanGesture)
        
        self.textGestureList.append(textPanGesture)
        self.textViewList.append(textView)
        self.currentTextView = textView
        
        textView.becomeFirstResponder()
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
    
    @IBAction func clearButtonTap(_ sender: Any) {
        textViewList.forEach { $0.removeFromSuperview() }
        textViewList.removeAll()
        textGestureList.removeAll()
        savedPaths.removeAll()
        self.renderCanvas()
    }
    
    // MARK: - Text
    @IBAction func textSizeSliderValueChanged(_ sender: Any) {
        if let textView = currentTextView, let font = textView.font {
            textView.font = font.withSize(CGFloat(textSizeSlider.value))
            self.textViewDidChange(textView)
        }
    }
    
    @objc func handleKeyboardTapGesture(_ gesture: UIPanGestureRecognizer) {
        if self.mode == .empty || self.mode == .text {
            self.doneButtonTap(doneButton)
        }
    }
    
    @objc func handleTextPanGesture(_ gesture: UIPanGestureRecognizer) {
        if self.mode == .empty || self.mode == .text {
            guard let view = gesture.view else { return }
            let location = gesture.translation(in: canvasImageView)
            switch gesture.state {
            case .began:
                
                break
                
            case .changed:
                view.transform = CGAffineTransform(translationX: location.x, y: location.y)
                break
                
            case .possible: break
                
            case .cancelled, .ended, .failed:
                let transform = view.transform
                let tx = transform.tx
                let ty = transform.ty
                let oldFrame = view.frame
                let newFrame = CGRect(x: oldFrame.origin.x + tx,
                                      y: oldFrame.origin.y + ty,
                                      width: oldFrame.width,
                                      height: oldFrame.height)
                view.frame = newFrame
                view.transform = .identity
                break
            }
        }
    }
    
    // MARK: - Drawing
    @objc func handleDrawingPanGesture(_ gesture: UIPanGestureRecognizer) {
        if self.mode == .draw {
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
            
            canvasImageView.image?.draw(in: CGRect(x: 0,
                                                   y: 0,
                                                   width: canvasImageView.frame.size.width,
                                                   height: canvasImageView.frame.size.height))
            
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
        
        if gestureRecognizer == keyboardTapGesture {
            let touchLocation = gestureRecognizer.location(in: nil)
            let isTouchOutsideToolbar = !bottomToolbar.frame.contains(touchLocation)
            
            return self.currentTextView != nil && isTouchOutsideToolbar
        }
        if gestureRecognizer == drawingPanGesture {
            return self.mode == .draw
        }
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            if self.textGestureList.contains(panGesture) {
                return self.mode == .empty || self.mode == .text
            }
        }
        return false
    }
}

extension PhotoEditorViewController: UITextViewDelegate {
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return self.mode == . empty || self.mode == .text
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        currentTextView = textView
        if let textColor = textView.textColor {
            self.drawingColor = textColor
        }
        if self.mode == .empty {
            self.mode = .text
        }
        textView.layer.borderWidth = 1
        if let fontSize = textView.font?.pointSize {
            textSizeSlider.value = Float(fontSize)
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        let oldCenter = textView.center
        let size = textView.sizeThatFits(CGSize(width: canvasImageView.frame.size.width, height: canvasImageView.frame.size.height))
        let newFrame = CGRect(x: oldCenter.x - (size.width / 2),
                              y: oldCenter.y - (size.height / 2),
                              width: size.width,
                              height: size.height)
        textView.frame = newFrame
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if currentTextView == textView {
            currentTextView = nil
            if textView.isFirstResponder {
                textView.resignFirstResponder()
            }
        }
        textView.layer.borderWidth = 0
    }
}

extension PhotoEditorViewController {
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            self.topScrollView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
            
            if let textView = self.currentTextView {
                self.topScrollView.scrollRectToVisible(textView.frame, animated: true)
            }
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let `self` = self else { return }
                self.bottomToolbar.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.topScrollView.contentInset = UIEdgeInsets.zero
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let `self` = self else { return }
            self.bottomToolbar.transform = CGAffineTransform.identity
        }
        
    }
}
