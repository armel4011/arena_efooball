import Flutter
import UIKit
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PKPushRegistryDelegate {

  /// Registre PushKit — doit rester fortement référencé, sinon iOS le
  /// libère et plus aucun push VoIP n'est délivré.
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // PushKit VoIP : seul moyen de réveiller l'app (même tuée) pour un
    // appel entrant et de présenter l'UI CallKit par-dessus le verrou.
    // FCM ne sait pas livrer de push VoIP — l'appel passe donc par un
    // push APNs VoIP dédié (cf. Edge Function `dispatch_notification`).
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - PKPushRegistryDelegate

  /// Nouveau token VoIP : transmis au plugin CallKit, qui le relaie à
  /// Dart (`actionDidUpdateDevicePushTokenVoip`) pour enregistrement
  /// serveur (`profiles.voip_token`).
  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate credentials: PKPushCredentials,
    for type: PKPushType
  ) {
    guard type == .voIP else { return }
    let token = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  /// Token VoIP invalidé : on l'efface côté serveur via le même canal.
  func pushRegistry(
    _ registry: PKPushRegistry,
    didInvalidatePushTokenFor type: PKPushType
  ) {
    guard type == .voIP else { return }
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  /// Push VoIP reçu : Apple EXIGE qu'on présente immédiatement l'appel
  /// via CallKit dans ce handler (sinon iOS tue l'app et coupe les
  /// pushs VoIP). `showCallkitIncoming(fromPushKit:)` fait ce report ;
  /// `completion()` n'est appelé qu'une fois le report effectué.
  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }
    let dict = payload.dictionaryPayload
    let id = dict["id"] as? String ?? UUID().uuidString
    let nameCaller = dict["nameCaller"] as? String ?? "Appel entrant"
    let handle = dict["handle"] as? String ?? ""
    let isVideo = dict["isVideo"] as? Bool ?? false

    let data = flutter_callkit_incoming.Data(
      id: id,
      nameCaller: nameCaller,
      handle: handle,
      type: isVideo ? 1 : 0
    )
    // `extra` (scope, scope_id, caller_id…) traverse jusqu'aux événements
    // Dart (`event.body['extra']`) — c'est ce que lit `_acceptCall`.
    if let extra = dict["extra"] as? [String: Any] {
      data.extra = extra as NSDictionary
    }
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(
      data,
      fromPushKit: true
    ) {
      completion()
    }
  }
}
