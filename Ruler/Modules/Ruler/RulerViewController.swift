//
//  RulerViewController.swift
//  Ruler
//
//  Created by Moon Dev on 4/11/24.
//  Copyright © 2024 Tbxark. All rights reserved.
//

import UIKit
import ARKit

class RulerViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var clearView: UIView!
    @IBOutlet weak var clearLb: UILabel!
    
    @IBOutlet weak var moreOnBtn: UIButton!
    @IBOutlet weak var moreOnStack: UIStackView!
    
    private var isMoreOn: Bool = false
    
    private let resultLabel = UILabel().then({
        $0.textAlignment = .center
        $0.textColor = UIColor.black
        $0.numberOfLines = 0
        $0.font = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.heavy)
    })
    private let indicator = UIImageView()
    
    private var line: LineNode?
    private var lineSet: LineSetNode?
    
    private var lines: [LineNode] = []
    private var lineSets: [LineSetNode] = []
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
    
    lazy var sceneView: ARSCNView = {
        let view = ARSCNView(frame: CGRect.zero)
        view.delegate = self
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = SCNAntialiasingMode.multisampling4X
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }

    private func layoutViewController() {
        let width = view.bounds.width
        let height = view.bounds.height
        view.backgroundColor = UIColor.black
        
        
        do {
            view.addSubview(sceneView)
            sceneView.frame = view.bounds
            sceneView.delegate = self
        }
        do {
            
            let resultLabelBg = UIView()
            resultLabelBg.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            resultLabelBg.layer.cornerRadius = 45
            resultLabelBg.clipsToBounds = true
            
            view.addSubview(resultLabel)
        }
        
        do {
            indicator.image = UIImage(named:
                                        "img_indicator_disable")
            view.addSubview(indicator)
            indicator.frame = CGRect(x: (width - 60)/2, y: (height - 60)/2, width: 60, height: 60)
        }
    }
    
    private func setUI() {
        cameraView.addSubview(sceneView)
        sceneView.frame = cameraView.bounds 
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        clearView.layer.cornerRadius = 16
        clearView.layer.masksToBounds = true
        clearLb.text = "Clear"
        
        moreOnBtn.setImage(UIImage(named:"more_off")
                           , for: .normal)
        moreOnStack.isHidden = true
        
    }
    
    @IBAction func moreAction(_ sender: Any) {
        isMoreOn = !isMoreOn
        moreOnBtn.setImage(UIImage(named: isMoreOn ? "more_on" : "more_off")
                           , for: .normal)
        moreOnStack.isHidden = !isMoreOn
        
    }
    
}
