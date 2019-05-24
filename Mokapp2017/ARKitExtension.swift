//
//  ARKitExtension.swift
//  TestARKit
//
//  Created by Daniele on 25/09/17.
//  Copyright © 2017 nexor. All rights reserved.
//

import UIKit
import ARKit

struct CollisionTypes : OptionSet {
    let rawValue: Int
    
    static let bottom  = CollisionTypes(rawValue: 1 << 0)
    static let shape = CollisionTypes(rawValue: 1 << 1)
}

extension GameViewController: ARSCNViewDelegate {

    func runSession() {
        
        guard ARWorldTrackingConfiguration.isSupported == true else {
            print("ARWorldTrackingConfiguration not supported")
            return
        }
        
        // Set the view's delegate
        scnView.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        
        if disablePlaneDetection == false {
        configuration.planeDetection = [.horizontal, .vertical]
        }
        
        configuration.isLightEstimationEnabled = true
        
        self.scnView.automaticallyUpdatesLighting = true
        self.scnView.autoenablesDefaultLighting = true
        
        self.scnView.scene.physicsWorld.contactDelegate = self

        //let options = [ARSession.RunOptions.resetTracking]
        self.scnView.antialiasingMode = .multisampling4X
        self.scnView.session.run(configuration, options: [])
    }
    
    func reset() {
        if let vcId = self.restorationIdentifier, let vc = self.storyboard?.instantiateViewController(withIdentifier: vcId), let kw = UIApplication.shared.keyWindow, let rvc = kw.rootViewController {
            vc.view.frame = rvc.view.frame
            vc.view.layoutIfNeeded()
            
            UIView.transition(with: kw, duration: 0.3, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
                kw.rootViewController = vc
            }, completion: nil)
        }
        else {
            self.scnView.debugOptions = []
            self.scnView.scene.rootNode.removeAllAnimations()
            self.scnView.scene.rootNode.removeAllParticleSystems()
            self.scnView.scene.rootNode.removeAllAudioPlayers()
//            for node in self.scnView.scene.rootNode.childNodes {
//                node.removeAllAnimations()
//                node.removeAllParticleSystems()
//                node.removeAllAudioPlayers()
//                node.removeFromParentNode()
//            }
        }
    }
    
    //MARK: - ARSCNViewDelegate
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            switch anchor {
            case let a where a is ARPlaneAnchor:
                let planeAnchor = a as! ARPlaneAnchor
                #if DEBUG
                    
                    let position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
                    let size = CGSize(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
                    
                    let color = UIColor.blue.withAlphaComponent(0.4)
                    let planeNode = SCNNode.createPlaneBoxNode(position: position, size: size, color: color)

                    guard let geometry = planeNode.geometry else {
                        print("Add plane error: Plane has not geometry!")
                        return
                    }
                    
                    SCNNode.setPhysicsToNode(node: planeNode, type: .kinematic, restituition: 0, friction: 1, geometry: geometry)
                    
                    planeNode.physicsBody?.categoryBitMask = CollisionTypes.bottom.rawValue
                    planeNode.physicsBody?.contactTestBitMask = CollisionTypes.shape.rawValue
//                    node.physicsBody?.collisionBitMask = 0
                    planeNode.physicsBody?.mass = 10
                    
                    self.existingNodes = [anchor.identifier.uuidString : planeNode]
                    node.addChildNode(planeNode)
                #endif
                break
            case let a where a is ARFaceAnchor:
                #if DEBUG
                    let faceAnchor = a as! ARFaceAnchor
                    let faceNode = SCNNode.createSphereNode(radius: 25)
                    node.addChildNode(faceNode)
                #endif
                break
            default:
                break
            }
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            
            self.lblTrackingInfo?.text = self.updateTrackingInfo()
            
            //self.scnView.hitTest(sel., types: ARHitTestResult.ResultType.)
            
            let key = anchor.identifier.uuidString
            let existingNode: SCNNode? = self.existingNodes[key]
            
            switch anchor {
            case let a where a is ARPlaneAnchor:
                let planeAnchor = a as! ARPlaneAnchor
                if let node = existingNode {
                    SCNNode.updatePlaneNode(node: node, center: planeAnchor.center, extent: planeAnchor.extent)
                }
                break
            case let a where a is ARFaceAnchor:
                //
                break
            default:
                switch node.name {
                case let a where a == DemoMode.upsideDown.rawValue:
                    
                    //node.position = SCNVector3Make(anchor.center.x, anchor.center.y, anchor.center.z)
                    break
                default:
                    break
                }
                
                break
            }
        }
    }
    
    
    public func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            
            let key = anchor.identifier.uuidString
            let existingNode: SCNNode? = self.existingNodes[key]
            
            switch anchor {
            case let a where a is ARPlaneAnchor:
                //This happens when multiple existing planes are merged into one.
                //Note that the didRemove method is not invoked when the user looks away from the plane, causing it to be off-screen. Even if a user is not looking at a node, it is still in memory and its position is mainted relative to where the user is currently pointing the camera.
                if let node = existingNode {
                    SCNNode.removeChildren(inNode: node)
                    self.existingNodes.removeValue(forKey: key)
                }
                break
            case let a where a is ARFaceAnchor:
                SCNNode.removeChildren(inNode: node)
                break
            default:
                break
            }
        }
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("error \(error)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        
    }
    
    func updateTrackingInfo() -> String? {
        guard let frame = self.scnView.session.currentFrame else {
            return nil
        }
        
        switch frame.camera.trackingState {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "Limited tracking: excessive motion"
            case .insufficientFeatures:
                return "Limited tracking: insufficient details"
            case .initializing:
                return "....initializing"
            case .relocalizing:
                return "....relocalizing"
            }
        default:
           break
        }
        
        guard let lightEstimate = frame.lightEstimate?.ambientIntensity else {
            return nil
        }
        
        if lightEstimate < 60 {
            return "Limited tracking: Too dark"
        }
        
        return nil
    }
    
}


let bottomWorldPlaneNodeName: String = "BottomWorldPlaneNode"

extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        DispatchQueue.main.async {
            if contact.nodeA.name == bottomWorldPlaneNodeName {
                contact.nodeB.removeFromParentNode()
                return
            }
            if contact.nodeB.name == bottomWorldPlaneNodeName {
                contact.nodeA.removeFromParentNode()
                return
            }
            
            self.spaceInvadersPhysicsWorld(world, didBegin: contact)
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        
    }
    
}
