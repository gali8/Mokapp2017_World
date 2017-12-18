//
//  MokappARKitExtension.swift
//  Mokapp2017
//
//  Created by Daniele on 11/11/17.
//  Copyright © 2017 nexor. All rights reserved.
//

import UIKit
import ARKit

enum ShapeType: Int {
    case box = 0
    case sphere
    case pyramid
    case torus
    case capsule
    case cylinder
    case cone
    case tube
    
    static func random() -> SCNGeometry {
        let maxValue = tube.rawValue
        let rand = arc4random_uniform(UInt32(maxValue+1))
        let type = ShapeType(rawValue: Int(rand))!
        
        let dimf = max(0.03, Float(arc4random_uniform(8))/100.0)
        let dim = CGFloat(dimf)
        let geometry: SCNGeometry
        switch type {
        case .box:
            geometry = SCNBox(width: dim, height: dim, length: dim, chamferRadius: 0.0)
        case .sphere:
            geometry = SCNSphere(radius: dim)
        case .pyramid:
            geometry = SCNPyramid(width: dim, height: dim, length: dim)
        case .torus:
            geometry = SCNTorus(ringRadius: dim, pipeRadius: dim/2)
        case .capsule:
            geometry = SCNCapsule(capRadius: dim/2, height: dim)
        case .cylinder:
            geometry = SCNCylinder(radius: dim, height: dim/2)
        case .cone:
            geometry = SCNCone(topRadius: dim/2, bottomRadius: dim, height: dim)
        case .tube:
            geometry = SCNTube(innerRadius: dim/2, outerRadius: dim, height: dim)
        }
        
        geometry.firstMaterial?.diffuse.contents = UIColor.random()
        return geometry
    }
}

extension GameViewController {
    
    func createBottomWorldPlane() {
        let position = SCNVector3(0, -10, 0)
        
        let size = CGSize(width: 1000, height: 1000)
        //boxnode not required transformation
        let bottomWorldPlaneNode = SCNNode.createPlaneBoxNode(position: position, size: size, color: UIColor.clear)
        
        let (newposition, rotation) = self.convertCameraPosition(position: bottomWorldPlaneNode.position)
        bottomWorldPlaneNode.position = newposition
        bottomWorldPlaneNode.rotation = rotation
        
        guard let geometry = bottomWorldPlaneNode.geometry else {
            print("Add plane error: Plane has not geometry!")
            return
        }
        
        SCNNode.setPhysicsToNode(node: bottomWorldPlaneNode, type: .kinematic, geometry: geometry)
        bottomWorldPlaneNode.physicsBody?.categoryBitMask = CollisionTypes.bottom.rawValue
        bottomWorldPlaneNode.physicsBody?.contactTestBitMask = CollisionTypes.shape.rawValue
        //bottomWorldPlaneNode.physicsBody?.collisionBitMask = 0
        bottomWorldPlaneNode.name = bottomWorldPlaneNodeName
        
        self.scnView.scene.rootNode.addChildNode(bottomWorldPlaneNode)
    }
    
    func showHideStatistics() {
        self.scnView.showsStatistics = !scnView.showsStatistics
    }
    
    func showDebugOptions() {
        self.scnView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }
    
    func showShape(light: Bool = true, gravity: Bool = false, updateToCamera: Bool = true, position: SCNVector3 = SCNVector3(x: 0, y: 0, z: -1)) {
        let shape = ShapeType.random()
        let node = SCNNode(geometry: shape)
        node.position = position
        //convert position to visible camera area
        
        if updateToCamera == true {
            let (newposition, rotation) = self.convertCameraPosition(position: node.position)
            node.position = newposition
            node.rotation = rotation
        }
        
        self.scnView.autoenablesDefaultLighting = light
        
        if gravity == true {
            SCNNode.setPhysicsToNode(node: node, type: .dynamic, mass: 1, restituition: 0.15, friction: 0.75, geometry: shape, isAffectedByGravity: true)
            node.physicsBody?.categoryBitMask = CollisionTypes.shape.rawValue
            //node.physicsBody?.collisionBitMask = 1
        }
        
        self.scnView.scene.rootNode.addChildNode(node)
    }
    
    func showUpsideDown() {
        
        if let _ = self.scnView.scene.rootNode.childNode(withName: "UpsideDownVideoPlayer", recursively: true) {
            print("player already added")
            return
        }
        
        let geometryH = SCNBox(width: 10, height: 10, length: 10, chamferRadius: 0.0)
        let geometryV = SCNBox(width: 10, height: 10, length: 10, chamferRadius: 0.0)
        geometryV.materials.first?.diffuse.contents = UIColor.black.withAlphaComponent(0.7)
        
        guard let particleHF = DemoMode.upsideDown.particle(geometry: geometryH), let particleVF = DemoMode.upsideDown.particle(geometry: geometryV), let particleHB = DemoMode.upsideDown.particle(geometry: geometryH), let particleVB = DemoMode.upsideDown.particle(geometry: geometryV) else {
            return
        }
        
        //particleHF
        
        //particleVF
        particleVF.acceleration.y = particleHF.acceleration.x
        particleVF.acceleration.y = -(particleHF.acceleration.y - 0.2)
        particleVF.acceleration.z = particleVF.acceleration.z
        
        //particleHB
        particleHB.acceleration = particleVF.acceleration
        particleHB.acceleration.x = -particleHF.acceleration.x
        particleHB.acceleration.z = -particleVF.acceleration.z
        
        //particleVB
        particleVB.acceleration = particleHB.acceleration
        particleVB.acceleration.x = -(particleVB.acceleration.x - 0.2)
        
        guard let urlString = Bundle.main.path(forResource: "strangerThingsSigla", ofType: "mp4") else {
            return
        }
        
        let url = URL(fileURLWithPath: urlString)
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        let videoSpriteKitNode = SKVideoNode(avPlayer: player)
        
        //let videoSpriteKitNode = SKVideoNode(fileNamed: "strangerThingsSigla.mp4")
        
        let size = CGSize(width: 1280, height: 720)
        videoSpriteKitNode.size = size
        videoSpriteKitNode.position = CGPoint(x: videoSpriteKitNode.size.width/2.0, y: videoSpriteKitNode.size.height/2.0)
        let spriteKitScene = SKScene(size: size)
        spriteKitScene.addChild(videoSpriteKitNode)
        
        videoSpriteKitNode.yScale = -1
        
        let videoNodeSize = CGSize(width: size.width/900, height: size.height/900)
        let videoNode = SCNNode()
        videoNode.geometry = SCNPlane(width: videoNodeSize.width, height: videoNodeSize.height)
        videoNode.geometry?.firstMaterial?.diffuse.contents = spriteKitScene
        videoNode.geometry?.firstMaterial?.isDoubleSided = true
        videoNode.position = SCNVector3(0, 0, -2)
        
        let videoParticleNodeF = SCNNode()
        videoParticleNodeF.addParticleSystem(particleHF)
        videoParticleNodeF.addParticleSystem(particleVF)
        videoParticleNodeF.position = SCNVector3(-videoNodeSize.width/2, 0, 0.01)
        
        let videoParticleNodeB = SCNNode()
        videoParticleNodeB.addParticleSystem(particleHB)
        videoParticleNodeB.addParticleSystem(particleVB)
        videoParticleNodeB.position = SCNVector3(videoNodeSize.width/2, 0, -0.01)
        
        videoNode.addChildNode(videoParticleNodeF)
        videoNode.addChildNode(videoParticleNodeB)
        
        //convert position to visible camera area
        let (position, rotation) = self.convertCameraPosition(position: videoNode.position) //self.scnView.pointOfView!.convertPosition(videoNode.position, to: self.scnView.scene.rootNode)
        videoNode.position = position
        videoNode.rotation = rotation
        
        videoNode.name = "UpsideDownVideoPlayer"
        
        //self.scnView.pointOfView?.addChildNode(videoNode)
        
        self.scnView.scene.rootNode.addChildNode(videoNode)
        
        videoSpriteKitNode.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (notification) in
            player.seek(to: kCMTimeZero)
            player.play()
            print("reset video")
        }
    }
    
    func showEarth(node: SCNNode? = nil) {
        guard let earthNode =  DemoMode.earth.node() else {
            return
        }
        
        earthNode.position = SCNVector3(0, 0, -2)
        
        //convert position to visible camera area
        let (position, _) = self.convertCameraPosition(position: earthNode.position)
        earthNode.position = position
        
        if let n = node {
            n.addChildNode(earthNode)
        }
        else {
            self.scnView.scene.rootNode.addChildNode(earthNode)
        }
        
        if earthNode.action(forKey: "EarthRotation") == nil {
            let height = earthNode.boundingBox.max.y - earthNode.boundingBox.min.y
            let pole = SCNCylinder(radius: 0.02, height: CGFloat(height + 0.4))
            pole.firstMaterial?.diffuse.contents = UIColor.blue
            let poleNode = SCNNode(geometry: pole)
            earthNode.addChildNode(poleNode)
            
            //SceneKit applies these rotations relative to the node’s pivot property in the reverse order of the components: first roll, then yaw, then pitch.
            earthNode.eulerAngles = SCNVector3(x: 0, y: 0, z: -0.23) //rotation on Pitch: x, Yaw (oscillata): y, Roll (rotolata): z angle axes. 23°
            //poleNode.eulerAngles = SCNVector3(x: 0, y: 1, z: 0)
            
            let action = SCNAction.rotateBy(x: 0, y: CGFloat(Double.pi*2), z: 0, duration: 10) //360
            let repeatAction = SCNAction.repeatForever(action)
            earthNode.runAction(repeatAction, forKey: "EarthRotation")
        }
    }
    
    func showTucano(node: SCNNode? = nil) {
        guard let tucanoNode =  DemoMode.tucano.node()?.clone() else {
            return
        }
        
        tucanoNode.position = SCNVector3(0, -0.1, -0.5)
        
        //convert position to visible camera area
        let (position, _) = self.convertCameraPosition(position: tucanoNode.position) //self.scnView.pointOfView!.convertPosition(videoNode.position, to: self.scnView.scene.rootNode)
        tucanoNode.position = position
        //tucanoNode.rotation = rotation
        
        if let n = node {
            n.addChildNode(tucanoNode)
        }
        else {
            self.scnView.scene.rootNode.addChildNode(tucanoNode)
        }
    }
    
    func showSpaceInvaders() {
        loadSpaceInvaders()
    }
}

