//
//  RulerViewController.swift
//  Ruler
//
//  Created by Moon Dev on 4/11/24.
//  Copyright © 2024 Tbxark. All rights reserved.
//

import UIKit
import ARKit
import Photos

class RulerViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var clearView: UIView!
    @IBOutlet weak var clearLb: UILabel!
    
    @IBOutlet weak var moreOnBtn: UIButton!
    @IBOutlet weak var moreOnStack: UIStackView!
    
    private let sceneView: ARSCNView =  ARSCNView(frame: UIScreen.main.bounds)
    
    private let indicator = UIImageView()
    private let resultLabel = UILabel().then({
        $0.textAlignment = .center
        $0.textColor = UIColor.black
        $0.numberOfLines = 0
        $0.font = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.heavy)
    })
    
    private var line: LineNode?
    
    private var lines: [LineNode] = []
    private var listLineSave: [LineNode] = []
    private var planes = [ARPlaneAnchor: Plane]()
    private var focusSquare: FocusSquare?
    
    private var finishButtonState = false
    private var lastState: ARCamera.TrackingState = .notAvailable {
        didSet {
            switch lastState {
                case .notAvailable:
                    guard HUG.isVisible else { return }
                    HUG.show(title: Localization.arNotAvailable.toString())
                case .limited(let reason):
                    switch reason {
                        case .initializing:
                            HUG.show(title: Localization.arInitializing.toString(), message: Localization.arInitializingMessage.toString(), inSource: self, autoDismissDuration: nil)
                        case .insufficientFeatures:
                            HUG.show(title: Localization.arExcessiveMotion.toString(), message: Localization.arInitializingMessage.toString(), inSource: self, autoDismissDuration: 5)
                        case .excessiveMotion:
                            HUG.show(title: Localization.arExcessiveMotion.toString(), message: Localization.arExcessiveMotionMessage.toString(), inSource: self, autoDismissDuration: 5)
                        case .relocalizing:
                            HUG.show(title: Localization.arRelocalizing.toString(), message: Localization.arRelocalizing.toString(), inSource: self, autoDismissDuration: 5)
                    }
                case .normal:
                    HUG.dismiss()
            }
        }
    }
    private var measureUnit = ApplicationSetting.Status.defaultUnit {
        didSet {
            let v = measureValue
            measureValue = v
        }
    }
    private var measureValue: MeasurementUnit? {
        didSet {
            if let m = measureValue {
                resultLabel.text = nil
                resultLabel.attributedText = m.attributeString(type: measureUnit)
            }
        }
    }
    
    private var isMoreOn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViewController()
        setupFocusSquare()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restartSceneView()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func layoutViewController() {
        let width = view.bounds.width
        let height = view.bounds.height
        view.backgroundColor = UIColor.black
        
        do {
            cameraView.addSubview(sceneView)
            sceneView.frame = view.bounds
            sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            sceneView.delegate = self
        }
        
        do {
            indicator.image = UIImage(named: "img_indicator_disable")
            view.addSubview(indicator)
            indicator.frame = CGRect(x: (width - 60)/2, y: (height - 60)/2, width: 60, height: 60)
        }
    }
    
    @IBAction func moreAction(_ sender: Any) {
        isMoreOn = !isMoreOn
        moreOnBtn.setImage(UIImage(named: isMoreOn ? "more_on" : "more_off")
                           , for: .normal)
        moreOnStack.isHidden = !isMoreOn
    }
    
    @IBAction func addAction(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction, .curveEaseOut], animations: {
            sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (value) in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                sender.transform = CGAffineTransform.identity
            })
        }
        
        if let l = line {
            lines.append(l)
            line = nil
        } else {
            let startPos = sceneView.worldPositionFromScreenPosition(indicator.center,
                                                                     objectPos: nil)
            if let p = startPos.position {
                line = LineNode(startPos: p,
                                sceneV: sceneView)
            }
        }
    }
    
    @IBAction func saveAction(_ sender: Any) {
        guard let currentFrame = sceneView.session.currentFrame else {
            print("Không thể lấy ARFrame.")
            return
        }
        
        let renderer = SCNRenderer(device: sceneView.device, options: nil)
        renderer.scene = sceneView.scene
        renderer.pointOfView = sceneView.pointOfView
        
        let imageSize = sceneView.bounds.size
        let scale = UIScreen.main.scale
        let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        let snapshot = renderer.snapshot(atTime: currentFrame.timestamp, with: scaledImageSize, antialiasingMode: .multisampling4X)
        
        UIImageWriteToSavedPhotosAlbum(snapshot, nil, nil, nil)
        print("Đã chụp toàn bộ LineNode trong AR thành công!")
    }
    
    private func configureObserver() {
        func cleanLine() {
            line?.removeFromParent()
            line = nil
            for node in lines {
                node.removeFromParent()
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground,
                                               object: nil,
                                               queue: OperationQueue.main) { _ in
            cleanLine()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


@objc private extension RulerViewController {
    func saveImage(_ sender: UIButton) {
        func saveImage(image: UIImage) {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { (isSuccess: Bool, error: Error?) in
                if let e = error {
                    HUG.show(title: Localization.saveFail.toString(), message: e.localizedDescription)
                } else{
                    HUG.show(title: Localization.saveSuccess.toString())
                }
            }
        }
        
        let image = sceneView.snapshot()
        switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:
                saveImage(image: image)
            default:
                PHPhotoLibrary.requestAuthorization { (status) in
                    switch status {
                        case .authorized:
                            saveImage(image: image)
                        default:
                            HUG.show(title: Localization.saveFail.toString(), message: Localization.saveNeedPermission.toString())
                    }
                }
        }
    }
    
    func changeFinishState(state: Bool) {
        guard finishButtonState != state else { return }
        finishButtonState = state
        // var center = placeButton.center
        if state {
            // center.y -= 100
        }
        UIView.animate(withDuration: 0.3) {
            //            self.finishButton.center = center
        }
    }
    
    // 变换测量单位
    func changeMeasureUnitAction(_ sender: UITapGestureRecognizer) {
        measureUnit = measureUnit.next()
    }
}


// MARK: - UI
fileprivate extension RulerViewController {
    func restartSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        measureUnit = ApplicationSetting.Status.defaultUnit
        updateFocusSquare()
    }
    
    func updateLine() -> Void {
        let startPos = sceneView.worldPositionFromScreenPosition(self.indicator.center, objectPos: nil)
        if let p = startPos.position {
            let camera = self.sceneView.session.currentFrame?.camera
            let cameraPos = SCNVector3.positionFromTransform(camera!.transform)
            if cameraPos.distanceFromPos(pos: p) < 0.05 {
                if line == nil {
                   // add.isEnabled = false
                    indicator.image = UIImage(named: "end_point")
                }
                return;
            }
            //    placeButton.isEnabled = true
            indicator.image = UIImage(named: "end_point")
            guard let currentLine = line else {
                // cancleButton.normalImage = Image.Close.delete
                return
            }
            let length = currentLine.updatePosition(pos: p, camera: self.sceneView.session.currentFrame?.camera, unit: measureUnit)
            measureValue =  MeasurementUnit(meterUnitValue: length, isArea: false)
        }
    }
}

// MARK: - Plane
fileprivate extension RulerViewController {
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        let plane = Plane(anchor, false)
        planes[anchor] = plane
        node.addChildNode(plane)
        indicator.image = UIImage(named: "end_point")
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
}

// MARK: - FocusSquare
fileprivate extension RulerViewController {
    
    func setupFocusSquare() {
        focusSquare?.isHidden = true
        focusSquare?.removeFromParentNode()
        focusSquare = FocusSquare()
        sceneView.scene.rootNode.addChildNode(focusSquare!)
    }
    
    func updateFocusSquare() {
        if ApplicationSetting.Status.displayFocus {
            focusSquare?.unhide()
        } else {
            focusSquare?.hide()
        }
        let (worldPos, planeAnchor, _) = sceneView.worldPositionFromScreenPosition(sceneView.bounds.mid,
                                                                                   objectPos: focusSquare?.position)
        if let worldPos = worldPos {
            focusSquare?.update(for: worldPos, planeAnchor: planeAnchor,
                                camera: sceneView.session.currentFrame?.camera)
        }
    }
}


// MARK: - ARSCNViewDelegate
extension RulerViewController: ARSCNViewDelegate {
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            HUG.show(title: (error as NSError).localizedDescription)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
            self.updateLine()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.addPlane(node: node, anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.updatePlane(anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.removePlane(anchor: planeAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let state = camera.trackingState
        DispatchQueue.main.async {
            self.lastState = state
        }
    }
}
