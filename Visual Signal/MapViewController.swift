//
//  MapViewController.swift
//  Visual Signal
//
//  Created by Ferdinand Lösch on 06/05/2022.
//  Copyright © 2022 Vergil Choi. All rights reserved.
//

import Foundation

import GameplayKit
import SceneKit
import UIKit

class MapViewController: UIViewController {
    var scene = SCNScene()
    var node: SCNNode?

    override func viewDidLoad() {
        super.viewDidLoad()

        let scnView = view as! SCNView

        scnView.scene = scene

        scnView.allowsCameraControl = true

        scnView.autoenablesDefaultLighting = true

        scnView.showsStatistics = true

        scnView.backgroundColor = UIColor.black

        guard let node = self.node else { return }

        print("Add node to scene.")

        scene.rootNode.addChildNode(node)

        scene.rootNode.camera?.zFar = 100_000_000
        scene.rootNode.camera?.zNear = 1
        scene.rootNode.camera?.orthographicScale = 1000
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    @IBAction func BackButton(_: Any) {
        dismiss(animated: true, completion: nil)
    }
}
