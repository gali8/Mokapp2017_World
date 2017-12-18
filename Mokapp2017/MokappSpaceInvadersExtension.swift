//
//  MokappSpaceInvadersExtension.swift
//  Mokapp2017
//
//  Created by Daniele on 17/11/17.
//  Copyright © 2017 nexor. All rights reserved.
//

import UIKit
import ARKit

//struct SpaceInvadersCollisionTypes : OptionSet {
//    let rawValue: Int
//
//    static let bottom  = CollisionTypes(rawValue: 1 << 0)
//    static let shape = CollisionTypes(rawValue: 1 << 1)
//}

extension CollisionTypes {
    static let cannon = CollisionTypes(rawValue: 1 << 0)
    static let monster = CollisionTypes(rawValue: 1 << 1)
    static let cannonBullet = CollisionTypes(rawValue: 1 << 3)
    
    static let monsterBullet = CollisionTypes(rawValue: 1 << 6)
    static let monstersContainer = CollisionTypes(rawValue: 1 << 7)
}

private let spaceInvadersContainer = SCNScene(named: "spaceInvaders.scnassets/spaceinvaders.scn")!.rootNode.childNode(withName: "spaceInvadersContainer", recursively: true)! //preload
private let spaceInvadersMonster1 = SCNScene(named: "spaceInvaders.scnassets/spaceinvaders.scn")!.rootNode.childNode(withName: "monster1", recursively: true)! //preload
private let spaceInvadersMonster2 = SCNScene(named: "spaceInvaders.scnassets/spaceinvaders.scn")!.rootNode.childNode(withName: "monster2", recursively: true)! //preload
private let spaceInvadersMonster3 = SCNScene(named: "spaceInvaders.scnassets/spaceinvaders.scn")!.rootNode.childNode(withName: "monster3", recursively: true)! //preload
private let spaceInvadersBullet = SCNScene(named: "spaceInvaders.scnassets/spaceinvaders.scn")!.rootNode.childNode(withName: "spaceInvadersBullet", recursively: true)! //preload

extension GameViewController {
    
    var loadedSpaceInvadersContainer: SCNNode? {
        get {
            return self.scnView.scene.rootNode.childNode(withName: "spaceInvadersContainer", recursively: true)
        }
    }
    
    func loadSpaceInvaders() {
        if let _ = self.loadedSpaceInvadersContainer {
            return
        }
        
        loadSpaceInvadersContainer()
        loadMonsters()
        addCannonCollision()
    }
    
    private func loadSpaceInvadersContainer() {
        let node = spaceInvadersContainer.clone()
        node.position = SCNVector3(x: 0, y: -0.5, z: -2.5)
        
        let (newposition, newRotation) = self.convertCameraPosition(position: node.position)
        node.position = newposition
        node.rotation = newRotation
        
        self.scnView.scene.rootNode.addChildNode(node)
    }
    
    private func loadMonsters() {
        guard let container = self.loadedSpaceInvadersContainer else {
            return
        }
        
        let monstersContainer = container.childNode(withName: "monsters", recursively: true)!
        
        let ml0 = [spaceInvadersMonster1.clone(), spaceInvadersMonster1.clone(), spaceInvadersMonster1.clone(), spaceInvadersMonster1.clone(), spaceInvadersMonster1.clone()]
        let ml1 = [spaceInvadersMonster2.clone(), spaceInvadersMonster2.clone(), spaceInvadersMonster2.clone(), spaceInvadersMonster2.clone(), spaceInvadersMonster2.clone()]
        let ml2 = [spaceInvadersMonster3.clone(), spaceInvadersMonster3.clone(), spaceInvadersMonster3.clone(), spaceInvadersMonster3.clone(), spaceInvadersMonster3.clone()]
        let ml3 = [spaceInvadersMonster1.clone(), spaceInvadersMonster3.clone(), spaceInvadersMonster2.clone(), spaceInvadersMonster1.clone(), spaceInvadersMonster2.clone()]
        
        let originalMonstersContainerX = -(monstersContainer.boundingBox.max.x - monstersContainer.boundingBox.min.x) / 2
        var monstersContainerX = originalMonstersContainerX
        var monstersContainerY: Float = 1 // (monstersContainer.boundingBox.max.y - monstersContainer.boundingBox.min.y) / 2
        
        monstersContainer.position = SCNVector3(x: monstersContainerX, y: monstersContainerX, z: 0)
        
        func insertMonsters(ml: [SCNNode]) {
            for m in ml {
                let mX = (m.boundingBox.max.x - m.boundingBox.min.x) / 2
                let mY = -(m.boundingBox.max.y - m.boundingBox.min.y) / 2
                m.position = SCNVector3(monstersContainerX + mX, monstersContainerY - mY, 0)
                
                SCNNode.setPhysicsToNode(node: m, type: .kinematic, geometry: m.geometry!)
                
                m.physicsBody?.categoryBitMask = CollisionTypes.monster.rawValue
                m.physicsBody?.contactTestBitMask = CollisionTypes.cannon.rawValue | CollisionTypes.cannonBullet.rawValue
                
                monstersContainer.addChildNode(m)
                monstersContainerX += 0.20
            }
            
            monstersContainerX = originalMonstersContainerX
            monstersContainerY += 0.20
        }
        
        insertMonsters(ml: ml0)
        insertMonsters(ml: ml1)
        insertMonsters(ml: ml2)
        insertMonsters(ml: ml3)
        
        addMonstersContainerMovement(node: monstersContainer)
        
        addMonstersLegsMovement(monsters: ml0)
        addMonstersLegsMovement(monsters: ml1)
        addMonstersLegsMovement(monsters: ml2)
        addMonstersLegsMovement(monsters: ml3)
        
        container.addChildNode(monstersContainer)
    }
    
    private func addCannonCollision() {
        guard let container = self.loadedSpaceInvadersContainer else {
            return
        }
        
        let cannon = container.childNode(withName: "spaceInvadersCannon", recursively: true)!
        
        SCNNode.setPhysicsToNode(node: cannon, type: .kinematic, geometry: cannon.geometry!)
        
        cannon.physicsBody?.categoryBitMask = CollisionTypes.cannon.rawValue //CollisionTypes.cannon.rawValue
    }
    
    private func addMonstersContainerMovement(node: SCNNode) {
        let actionToRight = SCNAction.moveBy(x: 0.1, y: 0, z: 0, duration: 0.4)
        let actionToLeft = SCNAction.moveBy(x: -0.1, y: 0, z: 0, duration: 0.4)
        let actionToBottom = SCNAction.moveBy(x: 0, y: -0.15, z: 0, duration: 0.4)
        let actionMovementToDelay = SCNAction.wait(duration: 0.5)
        
        let sound0 = SCNAudioSource(fileNamed: "spaceinvaders_fastinvader1.wav")!
        let sound1 = SCNAudioSource(fileNamed: "spaceinvaders_fastinvader2.wav")!
        let actionMovementSound0 = SCNAction.playAudio(sound0, waitForCompletion: false)
        let actionMovementSound1 = SCNAction.playAudio(sound1, waitForCompletion: false)
        let actionMovementSoundDelay = SCNAction.wait(duration: 0.9)
        
        let actionMovementSoundSequence = SCNAction.sequence([actionMovementSound0, actionMovementSoundDelay, actionMovementSound1, actionMovementSoundDelay])
        
        let actionMovementSoundsRepeat = SCNAction.repeatForever(actionMovementSoundSequence)
        
        let actionsToRightSequence = SCNAction.sequence([actionToRight, actionMovementToDelay])
        let actionsToLeftSequence = SCNAction.sequence([actionToLeft, actionMovementToDelay])
        let actionsToRightRepeat = SCNAction.repeat(actionsToRightSequence, count: 9)
        let actionsToLeftRepeat = SCNAction.repeat(actionsToLeftSequence, count: 9)
        
        let actionsSequence = SCNAction.sequence([actionsToRightRepeat, actionToBottom, actionMovementToDelay, actionsToLeftRepeat, actionToBottom, actionMovementToDelay])
        let actionToRepeat = SCNAction.repeatForever(actionsSequence)
        
        let actions = SCNAction.group([actionMovementSoundsRepeat, actionToRepeat])
        
        node.runAction(actions, forKey: "MonstersContainerMovement")
    }
    
    private func addMonstersLegsMovement(monsters: [SCNNode]) {
        let actionLegUpToRight = SCNAction.moveBy(x: 0.01, y: 0, z: 0, duration: 0.4)
        let actionLegUpToLeft = SCNAction.moveBy(x: -0.01, y: 0, z: 0, duration: 0.4)
        let actionLegDownToRight = SCNAction.moveBy(x: 0.02, y: 0, z: 0, duration: 0.4)
        let actionLegDownToLeft = SCNAction.moveBy(x: -0.02, y: 0, z: 0, duration: 0.4)
        let actionMovementToDelay = SCNAction.wait(duration: 0.5)
        
        let actionLegLeftDownSequence = SCNAction.sequence([actionLegDownToRight, actionMovementToDelay, actionLegDownToLeft, actionMovementToDelay])
        let actionLegRightDownSequence = SCNAction.sequence([actionLegDownToLeft, actionMovementToDelay, actionLegDownToRight, actionMovementToDelay])
        let actionLegLeftUpSequence = SCNAction.sequence([actionLegUpToLeft, actionMovementToDelay, actionLegUpToRight, actionMovementToDelay])
        let actionLegRightUpSequence = SCNAction.sequence([actionLegUpToRight, actionMovementToDelay, actionLegUpToLeft, actionMovementToDelay])
        
        let actionLegLeftDownRepeat = SCNAction.repeatForever(actionLegLeftDownSequence)
        let actionLegRightDownRepeat = SCNAction.repeatForever(actionLegRightDownSequence)
        let actionLegLeftUpRepeat = SCNAction.repeatForever(actionLegLeftUpSequence)
        let actionLegRightUpRepeat = SCNAction.repeatForever(actionLegRightUpSequence)
        
        for m in monsters {
            let legLeftDown = m.childNode(withName: "leg_left_down", recursively: true)
            let legRightDown = m.childNode(withName: "leg_right_down", recursively: true)
            let legLeftUp = m.childNode(withName: "leg_left_up", recursively: true)
            let legRightUp = m.childNode(withName: "leg_right_up", recursively: true)
            
            legLeftDown?.runAction(actionLegLeftDownRepeat, forKey: "MonstersLegLeftDownMovement")
            legRightDown?.runAction(actionLegRightDownRepeat, forKey: "MonstersLegRightDownMovement")
            legLeftUp?.runAction(actionLegLeftUpRepeat, forKey: "MonstersLegLeftUpMovement")
            legRightUp?.runAction(actionLegRightUpRepeat, forKey: "MonstersLegRightUpMovement")
        }
    }
    
    func moveCannonLeft() {
        if let cannonNode = self.scnView.scene.rootNode.childNode(withName: "spaceInvadersCannon", recursively: true) {
            var position = cannonNode.position
            position.x -= 0.1
            cannonNode.moveToPosition(position: position)
        }
    }
    
    func moveCannonRight() {
        if let cannonNode = self.scnView.scene.rootNode.childNode(withName: "spaceInvadersCannon", recursively: true) {
            var position = cannonNode.position
            position.x += 0.1
            cannonNode.moveToPosition(position: position)
        }
    }
    
    func shotCannon() {
        if let cannonNode = self.scnView.scene.rootNode.childNode(withName: "spaceInvadersCannon", recursively: true) {
            let bullet = spaceInvadersBullet.clone()
            
            SCNNode.setPhysicsToNode(node: bullet, type: .kinematic, geometry: bullet.geometry!)
            
            bullet.physicsBody?.categoryBitMask = CollisionTypes.cannonBullet.rawValue
            
            let sound0 = SCNAudioSource(fileNamed: "spaceinvaders_shoot.wav")!
            let actionShootSound0 = SCNAction.playAudio(sound0, waitForCompletion: false)
            let actionShoot = SCNAction.moveBy(x: 0, y: 3, z: 0, duration: 0.7)
            let actionGroup = SCNAction.group([actionShootSound0, actionShoot])
            bullet.runAction(actionGroup)
            bullet.position = cannonNode.position
            
            let removeActionWait = SCNAction.wait(duration: 5)
            let removeAction = SCNAction.removeFromParentNode()
            let sequence = SCNAction.sequence([removeActionWait, removeAction])
            bullet.runAction(sequence)
            
            cannonNode.parent!.addChildNode(bullet)
        }
    }
    
    func createExplosion(color: UIColor?, geometry: SCNGeometry, node: SCNNode) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        
        if let c = color {
            explosion.particleColor = c
        }
        
        //        explosion.emitterShape = geometry
        //        explosion.birthLocation = .surface
        //
        //        let rotationMatrix = SCNMatrix4MakeRotation(node.presentation.rotation.w, node.presentation.rotation.x,
        //                                                    node.presentation.rotation.y, node.presentation.rotation.z)
        //        let translationMatrix = SCNMatrix4MakeTranslation(node.presentation.position.x, node.presentation.position.y,
        //                                                          node.presentation.position.z)
        //        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        
        let systemNode = SCNNode()
        systemNode.position = node.position
        systemNode.addParticleSystem(explosion)
        
        let removeActionWait = SCNAction.wait(duration: 5)
        let removeAction = SCNAction.removeFromParentNode()
        let sequence = SCNAction.sequence([removeActionWait, removeAction])
        systemNode.runAction(sequence)
        
        node.parent?.addChildNode(systemNode)
        
        //self.scnView.scene.addParticleSystem(explosion, transform: transformMatrix)
    }
    
    func spaceInvadersPhysicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let mask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        
        
        if CollisionTypes(rawValue: mask) == [CollisionTypes.cannon, CollisionTypes.monster] {
            if contact.nodeA.name ==  "spaceInvadersCannon" || contact.nodeB.name ==  "spaceInvadersCannon" {
                let node = contact.nodeA.name ==  "spaceInvadersCannon" ? contact.nodeA : contact.nodeB
                
                let child = node.childNode(withName: "box1", recursively: true)
                let color = child?.geometry?.firstMaterial?.diffuse.contents as? UIColor
                self.createExplosion(color: color, geometry: node.geometry!, node: node)
                
                let sound0 = SCNAudioSource(fileNamed: "spaceinvaders_explosion.wav")!
                let actionKilledSound0 = SCNAction.playAudio(sound0, waitForCompletion: true)
                
                node.parent?.runAction(actionKilledSound0)
                
                node.removeFromParentNode()
                
                self.youLose()
                //GAME OVER!!
                return
            }
        }
        
        if CollisionTypes(rawValue: mask) == [CollisionTypes.cannonBullet, CollisionTypes.monster] {
            if contact.nodeA.name ==  "spaceInvadersBullet" || contact.nodeB.name ==  "spaceInvadersBullet" {
                let node = contact.nodeA.name ==  "spaceInvadersBullet" ? contact.nodeB : contact.nodeA
                
                let child = node.childNode(withName: "head", recursively: true)
                let color = child?.geometry?.firstMaterial?.diffuse.contents as? UIColor
                self.createExplosion(color: color, geometry: node.geometry!, node: node)
                
                let sound0 = SCNAudioSource(fileNamed: "spaceinvaders_invaderkilled.wav")!
                let actionKilledSound0 = SCNAction.playAudio(sound0, waitForCompletion: true)
                
                node.parent?.runAction(actionKilledSound0)
                
                contact.nodeA.removeFromParentNode()
                contact.nodeB.removeFromParentNode()
                
                self.checkIfWin()
                return
            }
        }
    }
    
    func checkIfWin() {
        guard let container = self.loadedSpaceInvadersContainer else {
            return
        }
        
        if let monstersContainer = container.childNode(withName: "monsters", recursively: true) {
            let monsters1 = monstersContainer.childNode(withName: "monster1", recursively: true)
            let monsters2 = monstersContainer.childNode(withName: "monster2", recursively: true)
            let monsters3 = monstersContainer.childNode(withName: "monster3", recursively: true)
            
            if monsters1 != nil || monsters2 != nil || monsters3 != nil {
                //do nothing
            }
            else {
                stopMonstersContainer()
                self.lblTrackingInfo?.text = "You win!"
            }
        }
    }
    
    func youLose() {
        stopMonstersContainer()
        self.lblTrackingInfo?.text = "You LOSE!"
    }
    
    func stopMonstersContainer() {
        guard let container = self.loadedSpaceInvadersContainer else {
            return
        }
        
        if let monstersContainer = container.childNode(withName: "monsters", recursively: true) {
            monstersContainer.removeAllActions()
            let fadeAction = SCNAction.fadeOut(duration: 0.8)
            monstersContainer.runAction(fadeAction)
        }
    }
}
