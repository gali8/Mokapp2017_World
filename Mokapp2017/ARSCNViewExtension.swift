//
//  ARSCNViewExtension.swift
//  Mokapp2017
//
//  Created by Daniele on 12/11/17.
//  Copyright © 2017 nexor. All rights reserved.
//

import UIKit
import ARKit

protocol ARSCNViewProtocol {
    var scnView: ARSCNView! { get set }
    var existingNodes: [String: SCNNode] { get set }
}

extension ARSCNViewProtocol {
    
    func convertCameraPosition(position: SCNVector3) -> (position: SCNVector3, rotation: SCNVector4) {
        let camera = self.scnView.pointOfView!
        let p = camera.convertPosition(position, to: nil)
        let r = camera.rotation
        return (p, r)
    }
    
}

