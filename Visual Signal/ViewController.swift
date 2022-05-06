

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var strengthLabel: UILabel!

    @IBOutlet var recordButton: UIButton!
    var cameraTransform = simd_float4x4()
    var timer: Timer!
    var recordingTimer: Timer?
    var currentNode: SCNNode?
    var currentLabelNode: SCNNode?
    var link: CADisplayLink?
    var executionQ = [() -> Void]()
    var particleScen: SCNScene!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/main.scn")!
        particleScen = SCNScene(named: "art.scnassets/SceneKitScene.scn")

        // Set the scene to the view
        sceneView.scene = scene

        UIApplication.shared.isIdleTimerDisabled = true

        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        configuration.sceneReconstruction = .meshWithClassification

        configuration.environmentTexturing = .automatic
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isLightEstimationEnabled = true

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth
        }

        // Run the view's session
        sceneView.session.run(configuration)

        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
            self.strengthLabel.text = String(format: "  WiFi Strength: %.02f%%  ", self.wifiStrength() * 100)
        })
        timer.fire()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()

        timer.invalidate()
    }

    @IBAction func StartRecording(_: Any) {
        if recordingTimer != nil {
            recordButton.setTitle("start recording", for: .normal)
            recordingTimer?.invalidate()
            recordingTimer = nil
            return
        }

        recordButton.setTitle("stop recording", for: .normal)

        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            let signal = self.wifiStrength()
            self.executionQ.append {
                self.addParticleSystem(pos: self.sceneView.pointOfView!.worldPosition, signalStrength: signal)
            }
        })
        recordingTimer?.fire()
    }

    @IBAction func goToMap(_: Any) {
//        voxelMap.getVoxelMap(redrawAll: true, onlyObstacles: false) { v in
//            v.forEach { self.voxleRootNode.addChildNode($0) }
//            DispatchQueue.main.async {
//                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
//                if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "Map") as? MapViewController {
//                    viewController.node = self.voxleRootNode.clone()
//                    self.present(viewController, animated: true, completion: nil)
//                }
//            }
//        }
        recordingTimer?.invalidate()
        recordingTimer = nil
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "Map") as? MapViewController {
            viewController.scene.rootNode.addChildNode(sceneView.scene.rootNode)
            present(viewController, animated: true, completion: nil)
        }
    }

    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
//        let strength = wifiStrength()
//        let sphere = SCNSphere(radius: 0.01)
//        sphere.firstMaterial?.diffuse.contents = UIColor(
//            hue: CGFloat((2 * strength - strength * strength) / 2),
//            saturation: 1, brightness: 1, alpha: 1
//        )
//        currentLabelNode = TextNode(text: String(format: "%.02f%%", strength * 100), font: "AvenirNext-Regular", colour: UIColor(
//            hue: CGFloat((2 * strength - strength * strength) / 2),
//            saturation: 1, brightness: 1, alpha: 1
//        ))
//
//        currentNode = SCNNode(geometry: sphere)
//        updatePositionAndOrientationOf(currentNode!, withPosition: SCNVector3(0, 0, -0.15), relativeTo: sceneView.pointOfView!)
//
//        updatePositionAndOrientationOf(currentLabelNode!, withPosition: SCNVector3(0, 0.02, -0.15), relativeTo: sceneView.pointOfView!)
//        sceneView.scene.rootNode.addChildNode(currentNode!)
//        sceneView.scene.rootNode.addChildNode(currentLabelNode!)
//        addParticleSystem(pos: sceneView.pointOfView!.worldPosition, signalStrength: strength)
//
//        link = CADisplayLink(target: self, selector: #selector(scalingNode))
//        link?.add(to: RunLoop.main, forMode: .common)

//        guard let frame = sceneView.session.currentFrame else {
//            return
//        }
//        var meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }
//
//        print(meshAnchors.count)
    }

    override func touchesEnded(_: Set<UITouch>, with _: UIEvent?) {
        link?.invalidate()
    }

    @objc func scalingNode() {
        if let node = currentNode {
            node.scale = SCNVector3(node.scale.x + 0.02, node.scale.y + 0.02, node.scale.z + 0.02)
        }
        if let node = currentLabelNode {
            node.scale = SCNVector3(node.scale.x + 0.02, node.scale.y + 0.02, node.scale.z + 0.02)
            node.position.y += 0.0002
        }
    }

    func updatePositionAndOrientationOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) {
        let referenceNodeTransform = matrix_float4x4(referenceNode.transform)

        // Setup a translation matrix with the desired position
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = position.x
        translationMatrix.columns.3.y = position.y
        translationMatrix.columns.3.z = position.z

        // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
        node.transform = SCNMatrix4(updatedTransform)
    }

    func wifiStrength() -> Double {
        let statusBarManager = UIApplication.shared
            .keyWindow?
            .windowScene?
            .statusBarManager
        let hascreateLocalStatusBar = statusBarManager?
            .responds(to: Selector("createLocalStatusBar"))

        if !(hascreateLocalStatusBar ?? false) {
            return -1
        }

        guard let createLocalStatusBar = statusBarManager?
            .perform(Selector("createLocalStatusBar"))
            .takeUnretainedValue() as?
            UIView else { print("not UIVirw"); return 0 }

        let hasStatusBar = createLocalStatusBar.responds(to: Selector("statusBar"))
        if !hasStatusBar {
            return -1
        }

        let statusBar = (createLocalStatusBar.perform(Selector("statusBar"))
            .takeUnretainedValue() as! UIView)

        guard let value = (((statusBar.value(forKey: "_statusBar") as? NSObject)?
                .value(forKey: "_currentAggregatedData") as? NSObject)?
            .value(forKey: "_wifiEntry") as? NSObject)?
            .value(forKey: "_rawValue") else { return -1 }

        let dBm = value as! Int
        var strength = (Double(dBm) + 90.0) / 60.0

        if strength > 1 {
            strength = 1
        }
        return strength
    }

    func addParticleSystem(pos: SCNVector3, signalStrength: Double) {
        let particlesNode: SCNNode = (particleScen?.rootNode.childNode(withName: "particles", recursively: true)!)!.clone()

        let particleSystem: SCNParticleSystem = (particlesNode.particleSystems?.first)!.copy() as! SCNParticleSystem

        particlesNode.removeAllParticleSystems()

        particleSystem.particleColor = UIColor.red.blend(to: UIColor.green, percent: signalStrength)

        particlesNode.addParticleSystem(particleSystem)

        let nods = knownAnchors.map { $0.value }

        particleSystem.colliderNodes = nods
        particlesNode.position = pos

        sceneView.scene.rootNode.addChildNode(particlesNode)
    }

    func export() {
        let meshAnchors = sceneView.session.currentFrame?.anchors.compactMap { $0 as? ARMeshAnchor }

        DispatchQueue.global().async {
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename = directory.appendingPathComponent("Mesh.obj")

            guard let device = MTLCreateSystemDefaultDevice() else {
                print("metal device could not be created")
                return
            }

            let asset = MDLAsset()

            for anchor in meshAnchors! {
                let mdlMesh = anchor.geometry.toMDLMesh(device: device)
                asset.add(mdlMesh)
            }

            do {
                try asset.export(to: filename)
            } catch {
                print("failed to write to file")
            }
        }
    }

    // MARK: - ARSCNViewDelegate

    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
         let node = SCNNode()

         return node
     }
     */

    func session(_: ARSession, didFailWithError _: Error) {
        // Present an error message to the user
    }

    func sessionWasInterrupted(_: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }

    func sessionInterruptionEnded(_: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

    var knownAnchors = [UUID: SCNNode]()

//    func renderer(_: SCNSceneRenderer, updateAtTime _: TimeInterval) {
//        executionQ.forEach { $0() }
//    }

    func renderer(_: SCNSceneRenderer, didUpdate _: SCNNode, for _: ARAnchor) {
        executionQ.forEach { $0() }
        executionQ = []
    }

    func session(_: ARSession, didAdd anchors: [ARAnchor]) {
        print("didAdd")
        for anchor in anchors {
            var sceneNode: SCNNode?
            sceneNode?.name = "meshAnchor"

            if let meshAnchor = anchor as? ARMeshAnchor {
                let meshGeo = SCNGeometry.fromAnchor(meshAnchor: meshAnchor)
                sceneNode = SCNNode(geometry: meshGeo)
            } else if let planeAnchor = anchor as? ARPlaneAnchor {
                let planeGeo = ARSCNPlaneGeometry(device: sceneView.device!)
                planeGeo?.update(from: planeAnchor.geometry)
                planeGeo?.firstMaterial?.fillMode = .lines
                sceneNode = SCNNode(geometry: planeGeo)
            }

            if let node = sceneNode {
                node.simdTransform = anchor.transform
                knownAnchors[anchor.identifier] = node
                sceneView.scene.rootNode.addChildNode(node)
            }
        }
    }

    func session(_: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            // do we know about this anchor? If so update it
            if let node = knownAnchors[anchor.identifier] {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    let planeGeometry = node.geometry as! ARSCNPlaneGeometry
                    planeGeometry.update(from: planeAnchor.geometry)
                } else if let meshAnchor = anchor as? ARMeshAnchor {
                    // reconstruct it since we don't have an efficient way of updating the underlying data
                    node.geometry = SCNGeometry.fromAnchor(meshAnchor: meshAnchor)
                }
                node.simdTransform = anchor.transform
            }
        }
    }
}

// https://stackoverflow.com/questions/50678671/setting-up-the-orientation-of-3d-text-in-arkit-application
class TextNode: SCNNode {
    var textGeometry: SCNText!

    /// Creates An SCNText Geometry
    ///
    /// - Parameters:
    ///   - text: String (The Text To Be Displayed)
    ///   - depth: Optional CGFloat (Defaults To 1)
    ///   - font: UIFont
    ///   - textSize: Optional CGFloat (Defaults To 3)
    ///   - colour: UIColor
    init(text: String, depth: CGFloat = 0.01, font: String = "Helvatica", textSize: CGFloat = 1, colour: UIColor) {
        super.init()

        // 1. Create A Billboard Constraint So Our Text Always Faces The Camera
        let constraints = SCNBillboardConstraint()

        // 2. Create An SCNNode To Hold Out Text
        let node = SCNNode()
        let max, min: SCNVector3
        let tx, ty, tz: Float

        // 3. Set Our Free Axes
        constraints.freeAxes = .Y

        // 4. Create Our Text Geometry
        textGeometry = SCNText(string: text, extrusionDepth: depth)

        // 5. Set The Flatness To Zero (This Makes The Text Look Smoother)
        textGeometry.flatness = 0

        // 6. Set The Alignment Mode Of The Text
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue

        // 7. Set Our Text Colour & Apply The Font
        textGeometry.firstMaterial?.diffuse.contents = colour
        textGeometry.firstMaterial?.isDoubleSided = true
        textGeometry.font = UIFont(name: font, size: textSize)

        // 8. Position & Scale Our Node
        max = textGeometry.boundingBox.max
        min = textGeometry.boundingBox.min

        tx = (max.x - min.x) / 2.0
        ty = min.y
        tz = Float(depth) / 2.0

        node.geometry = textGeometry
        node.scale = SCNVector3(0.01, 0.01, 0.1)
        node.pivot = SCNMatrix4MakeTranslation(tx, ty, tz)

        addChildNode(node)

        self.constraints = [constraints]
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class SpeedTest: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    typealias speedTestCompletionHandler = (_ megabytesPerSecond: Double?, _ error: Error?) -> Void

    var speedTestCompletionBlock: speedTestCompletionHandler?

    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!

    func checkForSpeedTest() {
        testDownloadSpeedWithTimout(timeout: 5.0) { speed, error in
            print("Download Speed:", speed ?? "NA")
            print("Speed Test Error:", error ?? "NA")
        }
    }

    func testDownloadSpeedWithTimout(timeout: TimeInterval, withCompletionBlock: @escaping speedTestCompletionHandler) {
        guard let url = URL(string: "https://images.apple.com/v/imac-with-retina/a/images/overview/5k_image.jpg") else { return }

        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = startTime
        bytesReceived = 0

        speedTestCompletionBlock = withCompletionBlock

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session.dataTask(with: url).resume()
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        bytesReceived! += data.count
        stopTime = CFAbsoluteTimeGetCurrent()
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        let elapsed = stopTime - startTime

        if let aTempError = error as NSError?, aTempError.domain != NSURLErrorDomain, aTempError.code != NSURLErrorTimedOut, elapsed == 0 {
            speedTestCompletionBlock?(nil, error)
            return
        }

        let speed = elapsed != 0 ? Double(bytesReceived) / elapsed / 1024.0 / 1024.0 : -1
        speedTestCompletionBlock?(speed, nil)
    }
}

extension UIApplication {
    var statusBarUIView: UIView? {
        if #available(iOS 13.0, *) {
            let tag = 3_848_245

            let keyWindow: UIWindow? = UIApplication.shared.windows.filter { $0.isKeyWindow }.first

            if let statusBar = keyWindow?.viewWithTag(tag) {
                return statusBar
            } else {
                let height = keyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
                let statusBarView = UIView(frame: height)
                statusBarView.tag = tag
                statusBarView.layer.zPosition = 999_999

                keyWindow?.addSubview(statusBarView)
                return statusBarView
            }

        } else {
            if responds(to: Selector(("statusBar"))) {
                return value(forKey: "statusBar") as? UIView
            }
        }
        return nil
    }
}

extension UIColor {
    // This function calculates a new color by blending the two colors.
    // A percent of 0.0 gives the "self" color
    // A percent of 1.0 gives the "to" color
    // Any other percent gives an appropriate color in between the two
    func blend(to: UIColor, percent: Double) -> UIColor {
        var fR: CGFloat = 0.0
        var fG: CGFloat = 0.0
        var fB: CGFloat = 0.0
        var tR: CGFloat = 0.0
        var tG: CGFloat = 0.0
        var tB: CGFloat = 0.0

        getRed(&fR, green: &fG, blue: &fB, alpha: nil)
        to.getRed(&tR, green: &tG, blue: &tB, alpha: nil)

        let dR = tR - fR
        let dG = tG - fG
        let dB = tB - fB

        let perc = min(1.0, max(0.0, percent))
        let rR = fR + dR * CGFloat(perc)
        let rG = fG + dG * CGFloat(perc)
        let rB = fB + dB * CGFloat(perc)

        return UIColor(red: rR, green: rG, blue: rB, alpha: 1.0)
    }
}
