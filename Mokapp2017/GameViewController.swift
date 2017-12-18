//
//  GameViewController.swift
//  Mokapp2017
//
//  Created by Daniele on 07/11/17.
//  Copyright © 2017 nexor. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import ARKit

class GameViewController: UIViewController, ARSCNViewProtocol {
        
    enum DemoMode: String {
        case upsideDown = "upsideDown"
        case upsideDownStars = "upsideDownStars"
        case tucano = "tucano"
        case earth = "earth"
        case nothing = "nothing"
        
        static private let tucanoNode = SCNScene(named: "tucano.scnassets/tucano.scn")!.rootNode.childNode(withName: "tucano", recursively: true) //preload
        static private let earthNode = SCNScene(named: "earth.scnassets/earth.scn")!.rootNode.childNode(withName: "earth", recursively: true) //preload
        
        func node() -> SCNNode? {
            switch self {
            case .tucano:
                return DemoMode.tucanoNode
            case .earth:
                return DemoMode.earthNode
            default:
                return nil
            }
        }
        
        func particle(geometry: SCNGeometry) -> SCNParticleSystem? {
            switch self {
            case .upsideDown:
                let particle = ParticleHelper.createUpsideDown(geometry: geometry)
                return particle
            case .upsideDownStars:
                let particle = ParticleHelper.createUpsideDownStars(geometry: geometry)
                return particle
            default:
                return nil
            }
        }
        
    }
    
    var disablePlaneDetection: Bool {
        get {
            let ud = UserDefaults.standard
            return ud.bool(forKey: "DisablePlaneDetection")
        }
        set {
            let ud = UserDefaults.standard
            ud.set(newValue, forKey: "DisablePlaneDetection")
            ud.synchronize()
        }
    }
    
    @IBOutlet weak var scnView: ARSCNView!
    @IBOutlet weak var cstMenu: NSLayoutConstraint!
    @IBOutlet weak var lblTrackingInfo: UILabel?
    @IBOutlet weak var scvContainer: UIScrollView!
    
    @IBOutlet weak var btnDisablePlaneDetection: UIButton?
    
    @IBOutlet weak var spaceInvadersController: UIView?
    
    var existingNodes: [String: SCNNode] = Dictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.lblTrackingInfo?.text = self.updateTrackingInfo()
        self.scvContainer.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        self.scvContainer.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        btnDisablePlaneDetection?.tintColor = disablePlaneDetection ? UIColor.red : UIColor.green

        self.runSession()
        
        //        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        //
        //        scnView.scene = scene
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        createBottomWorldPlane()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.scnView.session.pause()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.runSession()
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {        
        // check what nodes are tapped
        let touchLocation = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(touchLocation, options: [:])
        
        // check that we clicked on at least one object
        if let result = hitResults.first {
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
            
            //add object to exact tapped location
            /*
             let newLocation = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
             let newLampNode = lampNode?.clone()
             if let newLampNode = newLampNode {
             newLampNode.position = newLocation
             sceneView.scene.rootNode.addChildNode(newLampNode)
             }*/
        }
        
        
        //planes gravity
        let hitPlaneResults = self.scnView.hitTest(touchLocation, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        if let hitPlaneResult = hitPlaneResults.first, let _ = hitPlaneResult.anchor as? ARPlaneAnchor {
            let planeHitTestPosition = SCNVector3Make(hitPlaneResult.worldTransform.columns.3.x, hitPlaneResult.worldTransform.columns.3.y + 2, hitPlaneResult.worldTransform.columns.3.z)
            showShape(gravity: true, updateToCamera: false, position: planeHitTestPosition)
            return
        }
        //planes gravity
    }

    @IBAction func onStatistics(_ sender: Any) {
        showHideStatistics()
    }
    
    @IBAction func onShape(_ sender: Any) {
        showShape(light: false)
    }
    
    @IBAction func onShapeLight(_ sender: Any) {
        showShape()
    }
    
    @IBAction func onEarth(_ sender: UIButton) {
        showEarth()
    }
    
    @IBAction func onShapeGravity(_ sender: Any) {
        showShape(gravity: true)
    }
    
    @IBAction func onDebugOptions(_ sender: Any) {
        showDebugOptions()
    }
    
    @IBAction func onTucano(_ sender: Any) {
        showTucano()
    }
    
    @IBAction func onUpsideDown(_ sender: Any) {
        showUpsideDown()
    }
    
    @IBAction func onSpaceInvaders(_ sender: Any) {
        showSpaceInvaders()
        spaceInvadersController?.isHidden = false
    }
    
    @IBAction func onSpaceInvadersLeft(_ sender: Any) {
        moveCannonLeft()
    }
    
    @IBAction func onSpaceInvadersShot(_ sender: Any) {
        shotCannon()
    }
    
    @IBAction func onSpaceInvadersRight(_ sender: Any) {
        moveCannonRight()
    }
    
    
    @IBAction func onMenu(_ sender: Any) {
        showHideMenu()
    }

    @IBAction func onDisablePlaneDetectionColor(_ sender: Any) {
        disablePlaneDetection = !disablePlaneDetection
        reset()
    }
    
    @IBAction func onReset(_ sender: Any) {
        reset()
    }
    
    func showHideMenu() {
        let bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            self.cstMenu.constant = self.cstMenu.constant == 15 ? (-45 - bottomInset) : 15
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
