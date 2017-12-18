//
//  ParticleHelper.swift
//  Mokapp2017
//
//  Created by Daniele on 09/11/17.
//  Copyright © 2017 nexor. All rights reserved.
//

import UIKit
import SceneKit

class ParticleHelper: Any {

    class func createUpsideDown(color: UIColor? = nil, geometry: SCNGeometry) -> SCNParticleSystem {
        let particle = SCNParticleSystem(named: "UpsideDownParticle.scnp", inDirectory: nil)!
        if let c = color {
            particle.particleColor = c
        }
        particle.emitterShape = geometry
        return particle
    }
    class func createUpsideDownStars(color: UIColor? = nil, geometry: SCNGeometry) -> SCNParticleSystem {
        let particle = SCNParticleSystem(named: "UpsideDownStars.scnp", inDirectory: nil)!
        if let c = color {
            particle.particleColor = c
        }
        particle.emitterShape = geometry
        return particle
    }
}
