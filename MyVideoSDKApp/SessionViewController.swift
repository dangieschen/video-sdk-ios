//
//  SessionViewController.swift
//  MyVideoSDKApp
//

import UIKit
import ZoomVideoSDK
import AVFoundation

enum ControlOption: Int {
    case toggleVideo = 0, toggleAudio, shareScreen, endSession
}

class SessionViewController: UIViewController, UITabBarDelegate, ZoomVideoSDKDelegate {
    
    var loadingLabel: UILabel!
    var canvasView: UIView!
    var placeholderView: UIView!
    var tabBar: UITabBar!
    var toggleVideoBarItem: UITabBarItem!
    var toggleAudioBarItem: UITabBarItem!
    
    // The audio processor for virtual mic
    private let audioProcessor = AudioSourceProcessor()
    
    let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfa2V5IjoiZ19Bc0N0bmhRNkdic21wZlNMOVVfZyIsInJvbGVfdHlwZSI6MSwidHBjIjoiem9vbS1taWMtdGVzdC0yIiwidmVyc2lvbiI6MSwiaWF0IjoxNzMzODc3MTY5LCJleHAiOjE3MzM4ODA3Njl9.EkUlF7UfbE2-vFXMwcZQpxYC5YKTfc0I0fjBygcPeiU"
    let sessionName = "zoom-mic-test-2"
    let userName = "Dan G"
    
    override func loadView() {
        super.loadView()
        
        loadingLabel = UILabel(frame: .zero)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.text = "Loading Session..."
        view.addSubview(loadingLabel)

        canvasView = UIView(frame: .zero)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        
        placeholderView = UIView(frame: .zero)
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        placeholderView.isHidden = true
        view.addSubview(placeholderView)
        
        tabBar = UITabBar(frame: .zero)
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.isHidden = true
        view.addSubview(tabBar)

        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            placeholderView.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor),
            placeholderView.heightAnchor.constraint(equalToConstant: 120),
            
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tabBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tabBar.topAnchor.constraint(equalTo: canvasView.bottomAnchor)
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegate before joining the session.
        ZoomVideoSDK.shareInstance()?.delegate = self
        
        tabBar.delegate = self
        toggleVideoBarItem = UITabBarItem(title: "Stop Video", image: UIImage(systemName: "video.slash"), tag: ControlOption.toggleVideo.rawValue)
        toggleAudioBarItem = UITabBarItem(title: "Mute", image: UIImage(systemName: "mic.slash"), tag: ControlOption.toggleAudio.rawValue)
        let shareScreenBarItem = UITabBarItem(title: "Share Screen", image: UIImage(systemName: "square.and.arrow.up.circle"), tag: ControlOption.shareScreen.rawValue)
        let endSessionBarItem = UITabBarItem(title: "End Session", image: UIImage(systemName: "phone.down"), tag: ControlOption.endSession.rawValue)
        tabBar.items = [toggleVideoBarItem, toggleAudioBarItem, shareScreenBarItem, endSessionBarItem]

        let placeholderImageView = UIImageView(image: UIImage(systemName: "person.fill"))
        placeholderImageView.translatesAutoresizingMaskIntoConstraints = false
        placeholderImageView.contentMode = .scaleAspectFill
        let placeholderLabel = UILabel(frame: .zero)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = userName
        placeholderView.addSubview(placeholderImageView)
        placeholderView.addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            placeholderImageView.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor),
            placeholderImageView.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor),
            placeholderImageView.topAnchor.constraint(equalTo: placeholderView.topAnchor),
            
            placeholderLabel.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: placeholderImageView.bottomAnchor),
            placeholderLabel.bottomAnchor.constraint(equalTo: placeholderView.bottomAnchor)
        ])
        
        configureAudioDevicesAndJoinSession()
    }
    
    private func configureAudioDevicesAndJoinSession() {
        var useVirtualMic = false
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Set category and activate session
            try audioSession.setCategory(.playAndRecord,
                                         mode: .default,
                                         options: [.allowBluetooth, .mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }


        if let inputs = audioSession.availableInputs {
            print("Available input devices:")
            for input in inputs {
                print(" - \(input.portName) (\(input.portType))")
                // Check if the mic name contains "medaica"
                if input.portName.lowercased().contains("medaica") {
                    print("Found 'medaica' mic: \(input.portName). Will use virtual mic processing.")
                    useVirtualMic = true
                }
            }
        } else {
            print("No available input devices found. Using built-in mic without virtual processing.")
        }

        joinSession(useVirtualMic: useVirtualMic)
    }
    
    private func joinSession(useVirtualMic: Bool) {
        let sessionContext = ZoomVideoSDKSessionContext()
        sessionContext.token = token
        sessionContext.sessionName = sessionName
        sessionContext.userName = userName
        
        // If we found a "medaica" device, use virtual mic
        if useVirtualMic {
            print("Using virtual mic delegate.")
            sessionContext.virtualAudioMicDelegate = audioProcessor
        } else {
            print("Not using virtual mic delegate, defaulting to built-in mic.")
        }
        
        if (ZoomVideoSDK.shareInstance()?.joinSession(sessionContext)) != nil {
            print("Session join attempted")
        } else {
            let errorAlert = UIAlertController(title: "Error",
                                               message: "Join session failed. Check your token or sessionName.",
                                               preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            errorAlert.addAction(okAction)
            present(errorAlert, animated: true)
        }
    }
    
    // MARK: ZoomVideoSDKDelegate Methods
    
    func onSessionJoin() {
        print("Session joined callback")
        DispatchQueue.main.async {
            self.tabBar.isHidden = false
            self.loadingLabel.isHidden = true
        }
        
        guard let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
              let myUserVideoCanvas = myUser.getVideoCanvas() else {
            return
        }
        
        // If the user’s video is off, show placeholder until they turn it on.
        if let myVideoIsOn = myUserVideoCanvas.videoStatus()?.on, myVideoIsOn == true {
            myUserVideoCanvas.subscribe(with: self.canvasView, aspectMode: .panAndScan, andResolution: ._Auto)
            placeholderView.isHidden = true
        } else {
            placeholderView.isHidden = false
        }
    }
    
    func onSessionLeave() {
        let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf()
        if let usersVideoCanvas = myUser?.getVideoCanvas() {
            usersVideoCanvas.unSubscribe(with: canvasView)
        }
        if let usersSharingCanvas = myUser?.getShareCanvas() {
            usersSharingCanvas.unSubscribe(with: canvasView)
        }
        
        presentingViewController?.dismiss(animated: true)
    }
    
    func onError(_ error: ZoomVideoSDKError, detail: Int) {
        print("Zoom SDK Error: \(error), detail: \(detail)")
    }
    
    func onUserShareStatusChanged(_ helper: ZoomVideoSDKShareHelper?, user: ZoomVideoSDKUser?, status: ZoomVideoSDKReceiveSharingStatus) {
        let shareCanvas = user?.getShareCanvas()
        if status == .start {
            let error = shareCanvas?.subscribe(with: self.canvasView, aspectMode: .panAndScan, andResolution: ._Auto)
            print("Share subscribe error: \(String(describing: error?.rawValue))")
        } else if status == .stop {
            shareCanvas?.unSubscribe(with: canvasView)
        }
    }
    
    // MARK: UITabBarDelegate
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        tabBar.selectedItem = nil
        switch item.tag {
        case ControlOption.toggleVideo.rawValue:
            handleToggleVideo(item: item)
        case ControlOption.toggleAudio.rawValue:
            handleToggleAudio(item: item)
        case ControlOption.shareScreen.rawValue:
            handleShareScreen(item: item)
        case ControlOption.endSession.rawValue:
            handleEndSession(item: item)
        default:
            break
        }
    }
    
    private func handleToggleVideo(item: UITabBarItem) {
        tabBar.items![ControlOption.toggleVideo.rawValue].isEnabled = false
        
        // Create a background queue for video operations
        let videoQueue = DispatchQueue(label: "com.myapp.videoqueue", qos: .userInitiated)
        
        videoQueue.async {
            guard let videoHelper = ZoomVideoSDK.shareInstance()?.getVideoHelper(),
                  let usersVideoCanvas = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf()?.getVideoCanvas() else {
                DispatchQueue.main.async {
                    self.tabBar.items![ControlOption.toggleVideo.rawValue].isEnabled = true
                }
                return
            }
            
            let myVideoIsOn = usersVideoCanvas.videoStatus()?.on ?? false
            print("Current video status - isOn: \(myVideoIsOn)")
            
            if myVideoIsOn {
                let error = videoHelper.stopVideo()
                print("Stop video error: \(error.rawValue)")
                
                DispatchQueue.main.async {
                    self.toggleVideoBarItem.title = "Start Video"
                    self.toggleVideoBarItem.image = UIImage(systemName: "video")
                    self.placeholderView.isHidden = false
                    
                    // Unsubscribe from current video
                    usersVideoCanvas.unSubscribe(with: self.canvasView)
                }
            } else {
                let error = videoHelper.startVideo()
                print("Start video error: \(error.rawValue)")
                
                // Add a small delay to allow camera to initialize
                Thread.sleep(forTimeInterval: 0.5)
                
                DispatchQueue.main.async {
                    self.toggleVideoBarItem.title = "Stop Video"
                    self.toggleVideoBarItem.image = UIImage(systemName: "video.slash")
                    
                    // Subscribe to video canvas
                    let subscribeError = usersVideoCanvas.subscribe(with: self.canvasView,
                                                                  aspectMode: .panAndScan,
                                                                  andResolution: ._Auto)
                    print("Video subscribe error: \(String(describing: subscribeError.rawValue))")
                    
                    if subscribeError == .Errors_Success {
                        self.placeholderView.isHidden = true
                        print("Successfully subscribed to video canvas")
                    } else {
                        print("Failed to subscribe to video canvas")
                        self.placeholderView.isHidden = false
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.tabBar.items![ControlOption.toggleVideo.rawValue].isEnabled = true
            }
        }
    }
    
    func onUserVideoStatusChanged(_ helper: ZoomVideoSDKVideoHelper?, user: ZoomVideoSDKUser?, status: ZoomVideoSDKVideoStatus?) {
        print("Video status changed - User: \(String(describing: user?.getName()))")
        print("Video status - isOn: \(String(describing: status?.on))")
        
        guard let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
              user?.getID() == myUser.getID() else {
            return
        }
        
        DispatchQueue.main.async {
            if status?.on == true {
                if let canvas = user?.getVideoCanvas() {
                    let error = canvas.subscribe(with: self.canvasView,
                                              aspectMode: .panAndScan,
                                              andResolution: ._Auto)
                    print("Video subscribe error in status change: \(String(describing: error.rawValue))")
                    self.placeholderView.isHidden = true
                }
            } else {
                if let canvas = user?.getVideoCanvas() {
                    canvas.unSubscribe(with: self.canvasView)
                }
                self.placeholderView.isHidden = false
            }
        }
    }
    
    private func handleToggleAudio(item: UITabBarItem) {
        tabBar.items![ControlOption.toggleAudio.rawValue].isEnabled = false

        guard let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
              let audioHelper = ZoomVideoSDK.shareInstance()?.getAudioHelper() else {
            tabBar.items![ControlOption.toggleAudio.rawValue].isEnabled = true
            return
        }

        guard let audioStatus = myUser.audioStatus() else {
            tabBar.items![ControlOption.toggleAudio.rawValue].isEnabled = true
            return
        }

        // If no audio connected, start audio
        if audioStatus.audioType == .none {
            audioHelper.startAudio()
        } else {
            // If audio connected, toggle mute/unmute
            if audioStatus.isMuted {
                let error = audioHelper.unmuteAudio(myUser)
                print("Unmute error: \(error.rawValue)")
                toggleAudioBarItem.title = "Mute"
                toggleAudioBarItem.image = UIImage(systemName: "mic.slash")
            } else {
                let error = audioHelper.muteAudio(myUser)
                print("Mute error: \(error.rawValue)")
                toggleAudioBarItem.title = "Start Audio"
                toggleAudioBarItem.image = UIImage(systemName: "mic")
            }
        }

        tabBar.items![ControlOption.toggleAudio.rawValue].isEnabled = true
    }
    
    private func handleShareScreen(item: UITabBarItem) {
        tabBar.items![ControlOption.shareScreen.rawValue].isEnabled = false

        if let shareHelper = ZoomVideoSDK.shareInstance()?.getShareHelper() {
            let returnValue = shareHelper.startShare(with: loadingLabel)
            if returnValue == .Errors_Success {
                print("Sharing started successfully")
            } else {
                print("Failed to start sharing, error: \(returnValue)")
            }
        }

        tabBar.items![ControlOption.shareScreen.rawValue].isEnabled = true
    }
    
    private func handleEndSession(item: UITabBarItem) {
        tabBar.isUserInteractionEnabled = false
        self.loadingLabel.isHidden = true

        if let shareHelper = ZoomVideoSDK.shareInstance()?.getShareHelper() {
            let returnValue = shareHelper.stopShare()
            if returnValue == .Errors_Success {
                print("Stopped sharing successfully")
            } else {
                print("Failed to stop sharing: \(returnValue)")
            }
        }

        ZoomVideoSDK.shareInstance()?.leaveSession(true)
    }
}
