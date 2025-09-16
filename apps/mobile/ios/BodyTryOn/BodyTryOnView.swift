import UIKit
import RealityKit
import ARKit

final class BodyTryOnView: UIView, ARSessionDelegate {

  private let arView = ARView(frame: .zero)
  private var garmentEntity: Entity?
  private let garmentAnchor = AnchorEntity(.body)
  private var jointMap: [String: String] = [:]
  private var garmentLoadTask: Task<Void, Never>?

  @objc var garmentName: NSString = "tshirt" {
    didSet {
      scheduleGarmentLoad()
    }
  }

  @objc var jointMapResource: NSString = "GarmentJointMap" {
    didSet {
      loadJointMap(named: jointMapResource as String)
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    arView.translatesAutoresizingMaskIntoConstraints = false
    arView.automaticallyConfigureSession = false
    addSubview(arView)

    NSLayoutConstraint.activate([
      arView.topAnchor.constraint(equalTo: topAnchor),
      arView.bottomAnchor.constraint(equalTo: bottomAnchor),
      arView.leadingAnchor.constraint(equalTo: leadingAnchor),
      arView.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])

    arView.session.delegate = self
    arView.scene.addAnchor(garmentAnchor)

    loadJointMap(named: jointMapResource as String)
    configureSessionIfSupported()
    scheduleGarmentLoad()
  }

  private func configureSessionIfSupported() {
    guard ARBodyTrackingConfiguration.isSupported else {
      print("⚠️ ARBodyTrackingConfiguration non supportée sur cet appareil.")
      return
    }

    let configuration = ARBodyTrackingConfiguration()
    configuration.isAutoFocusEnabled = true
    configuration.environmentTexturing = .automatic
    arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
  }

  private func scheduleGarmentLoad() {
    let resourceName = garmentName as String
    garmentLoadTask?.cancel()
    garmentLoadTask = Task { [weak self] in
      await self?.loadGarment(named: resourceName)
    }
  }

  private func loadJointMap(named: String) {
    guard let url = Bundle.main.url(forResource: named, withExtension: "json") else {
      print("⚠️ Joint map \(named).json introuvable dans le bundle.")
      jointMap.removeAll()
      return
    }

    do {
      let data = try Data(contentsOf: url)
      if let dict = try JSONSerialization.jsonObject(with: data) as? [String: String] {
        jointMap = dict
      } else {
        print("⚠️ Impossible de parser le joint map JSON \(named).");
        jointMap.removeAll()
      }
    } catch {
      print("⚠️ Erreur lecture joint map: \(error)")
      jointMap.removeAll()
    }
  }

  private func removeCurrentGarment() {
    garmentEntity?.removeFromParent()
    garmentEntity = nil
  }

  private func loadGarment(named: String) async {
    guard !named.isEmpty else { return }

    let loadResult: Entity?
    if let url = Bundle.main.url(forResource: named, withExtension: "usdz") {
      do {
        loadResult = try await Entity.loadAsync(contentsOf: url).value
      } catch {
        print("⚠️ Erreur chargement USDZ (\(named).usdz): \(error)")
        loadResult = nil
      }
    } else {
      do {
        loadResult = try await Entity.loadAsync(named: named).value
      } catch {
        print("⚠️ Asset \(named) introuvable dans le bundle: \(error)")
        loadResult = nil
      }
    }

    guard let entity = loadResult else { return }

    await MainActor.run { [weak self] in
      guard let self else { return }
      removeCurrentGarment()
      garmentEntity = entity
      attachIfNeeded(entity)
      entity.position = [0, 1.4, 0]
    }
  }

  private func attachIfNeeded(_ entity: Entity) {
    if entity.parent == nil {
      garmentAnchor.addChild(entity)
    }
  }

  private func metersBetween(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
    simd_length(a - b)
  }

  private func shoulderSpanMeters(skeleton: ARSkeleton3D) -> Float? {
    guard let lIdx = skeleton.definition.index(for: .leftShoulder),
          let rIdx = skeleton.definition.index(for: .rightShoulder) else { return nil }
    let l = skeleton.jointModelTransforms[lIdx].columns.3
    let r = skeleton.jointModelTransforms[rIdx].columns.3
    return metersBetween(SIMD3<Float>(l.x, l.y, l.z), SIMD3<Float>(r.x, r.y, r.z))
  }

  private func scaleGarmentToBody(bodyAnchor: ARBodyAnchor) {
    if let span = shoulderSpanMeters(skeleton: bodyAnchor.skeleton) {
      let referenceShoulderSpan: Float = 0.42
      let scaleFactor = max(0.6, min(1.6, span / referenceShoulderSpan))
      garmentEntity?.scale = SIMD3<Float>(repeating: scaleFactor)
    }
  }

  private func applyFallbackAlignment(to garment: Entity, using bodyAnchor: ARBodyAnchor) {
    if let spineIdx = bodyAnchor.skeleton.definition.index(for: .spine7) {
      let matrix = bodyAnchor.transform * bodyAnchor.skeleton.jointModelTransforms[spineIdx]
      garment.transform.matrix = matrix
    }
  }

  private func applyARKitPose(to garment: Entity, using bodyAnchor: ARBodyAnchor) {
    guard #available(iOS 17.0, *) else {
      applyFallbackAlignment(to: garment, using: bodyAnchor)
      return
    }

    // TODO: RealityKit SDKs evolve quickly; confirm `SkeletalPosesComponent` naming on your Xcode version.
    guard var poses = garment.components[SkeletalPosesComponent.self] else {
      applyFallbackAlignment(to: garment, using: bodyAnchor)
      return
    }

    var jointTransforms = JointTransforms()
    let skeleton = bodyAnchor.skeleton

    for (arkitJointName, garmentJointName) in jointMap {
      guard let joint = ARSkeleton.JointName(rawValue: arkitJointName),
            let index = skeleton.definition.index(for: joint) else { continue }
      let jointTransform = skeleton.jointLocalTransforms[index]
      jointTransforms.setLocalTransform(jointTransform, forJointNamed: garmentJointName)
    }

    let pose = SkeletalPose(jointTransforms: jointTransforms)
    poses.setCurrentPose(pose)
    garment.components.set(poses)
  }

  // MARK: - ARSessionDelegate

  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    guard let bodyAnchor = anchors.compactMap({ $0 as? ARBodyAnchor }).first,
          let garment = garmentEntity else { return }

    scaleGarmentToBody(bodyAnchor: bodyAnchor)
    applyARKitPose(to: garment, using: bodyAnchor)
  }
}
