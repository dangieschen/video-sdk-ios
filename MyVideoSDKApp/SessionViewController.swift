//
//  SessionViewController.swift
//  MyVideoSDKApp
//
//

import UIKit
import ZoomVideoSDK

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
    
    // MARK: Session Information
    // TODO: Ensure that you do not hard code JWT or any other confidential credentials in your production app.
    let token = ""
    let sessionName = "MySesh"      // NOTE: Must match "tpc" field in JWT
    let userName = "My Username"
    
    // MARK: UI setup
    
    override func loadView() {
        super.loadView()
        
        loadingLabel = UILabel(frame: .zero)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingLabel)

        canvasView = UIView(frame: .zero)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        
        placeholderView = UIView(frame: .zero)
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderView)
        
        tabBar = UITabBar(frame: .zero)
        tabBar.translatesAutoresizingMaskIntoConstraints = false
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
        ZoomVideoSDK.shareInstance()?.delegate = self
        
        loadingLabel.text = "Loading Session..."

        tabBar.delegate = self
        toggleVideoBarItem = UITabBarItem(title: "Stop Video", image: UIImage(systemName: "video.slash"), tag: ControlOption.toggleVideo.rawValue)
        toggleAudioBarItem = UITabBarItem(title: "Mute", image: UIImage(systemName: "mic.slash"), tag: ControlOption.toggleAudio.rawValue)
        let shareScreenBarItem = UITabBarItem(title: "Share Screen", image: UIImage(systemName: "square.and.arrow.up.circle"), tag: ControlOption.shareScreen.rawValue)
        let endSessionBarItem = UITabBarItem(title: "End Session", image: UIImage(systemName: "phone.down"), tag: ControlOption.endSession.rawValue)
        tabBar.items = [toggleVideoBarItem, toggleAudioBarItem, shareScreenBarItem, endSessionBarItem]
        tabBar.isHidden = true
        
        let placeholderImageView = UIImageView(image: UIImage(systemName: "person.fill"))
        placeholderImageView.translatesAutoresizingMaskIntoConstraints = false
        placeholderImageView.contentMode = .scaleAspectFill
        let placeholderLabel = UILabel(frame: .zero)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = userName
        placeholderView.addSubview(placeholderImageView)
        placeholderView.addSubview(placeholderLabel)
        placeholderView.isHidden = true
        
        NSLayoutConstraint.activate([
            placeholderImageView.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor),
            placeholderImageView.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor),
            placeholderImageView.topAnchor.constraint(equalTo: placeholderView.topAnchor),
            
            placeholderLabel.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: placeholderImageView.bottomAnchor),
            placeholderLabel.bottomAnchor.constraint(equalTo: placeholderView.bottomAnchor)
        ])
        
        joinSession()
    }
    
    private func joinSession() {
        let sessionContext = ZoomVideoSDKSessionContext()
        sessionContext.token = token
        sessionContext.sessionName = sessionName
        sessionContext.userName = userName
        
        if let session = ZoomVideoSDK.shareInstance()?.joinSession(sessionContext) {
            // Session joined successfully.
            print("Session joined")
        } else {
            let errorAlert = UIAlertController(title: "Error", message: "Join session failed", preferredStyle: .alert)
            present(errorAlert, animated: true)
        }
    }
    
    // MARK: Delegate Callbacks
    func onSessionJoin() {
        // Render the current user's video
        if let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf(),
           // Get User's video canvas
           let myUserVideoCanvas = myUser.getVideoCanvas() {
            if let myVideoIsOn = myUserVideoCanvas.videoStatus()?.on,
               myVideoIsOn == false {
                DispatchQueue.main.async {
                    self.tabBar.isHidden = false
                    myUserVideoCanvas.subscribe(with: self.canvasView, aspectMode: .panAndScan, andResolution: ._Auto)
                }
            } else {
                print("No video status or it was on")
            }
        }
    }

    func onUserShareStatusChanged(_ helper: ZoomVideoSDKShareHelper?, user: ZoomVideoSDKUser?, status: ZoomVideoSDKReceiveSharingStatus) {
        // Get User's share canvas.
        let shareCanvas = user?.getShareCanvas()
        // Ensure that sharing has been started.
        if status == ZoomVideoSDKReceiveSharingStatus.start {
            // Set video aspect.
            let videoAspect = ZoomVideoSDKVideoAspect.panAndScan
            DispatchQueue.main.async {
                // Render the user's share stream.
                let error = shareCanvas?.subscribe(with: self.canvasView, aspectMode: videoAspect, andResolution: ._Auto)
                print("Share error: \(error!.rawValue)")
            }
        } else if status == ZoomVideoSDKReceiveSharingStatus.stop {
            shareCanvas?.unSubscribe(with: canvasView)
        }
    }
    
    func onSessionLeave() {
        let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf()
        // Get User's video canvas.
        if let usersVideoCanvas = myUser?.getVideoCanvas() {
            // Unsubscribe user's video canvas to stop rendering their video stream.
            usersVideoCanvas.unSubscribe(with: view)
        }
        presentingViewController?.dismiss(animated: true)
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        tabBar.selectedItem = nil
        switch item.tag {
        case ControlOption.toggleVideo.rawValue:
            tabBar.items![ControlOption.toggleVideo.rawValue].isEnabled = false
            
            if let usersVideoCanvas = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf()?.getVideoCanvas(),
               let videoHelper = ZoomVideoSDK.shareInstance()?.getVideoHelper() {
                if let myVideoIsOn = usersVideoCanvas.videoStatus()?.on,
                   myVideoIsOn == true {
                    let error = videoHelper.stopVideo()
                    print("Stop error: \(error.rawValue)")
                    toggleVideoBarItem.title = "Start Video"
                    toggleVideoBarItem.image = UIImage(systemName: "video")
                    placeholderView.isHidden = false
                } else {
                    let error = videoHelper.startVideo()
                    print("Start error: \(error.rawValue)")
                    self.toggleVideoBarItem.title = "Stop Video"
                    toggleVideoBarItem.image = UIImage(systemName: "video.slash")
                    placeholderView.isHidden = true
                }
                
                tabBar.items![ControlOption.toggleVideo.rawValue].isEnabled = true
            }
            return
        case ControlOption.toggleAudio.rawValue:
            tabBar.items![ControlOption.toggleAudio.rawValue].isEnabled = false

            let myUser = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf()
            // Get the user's audio status
            if let audioStatus = myUser?.audioStatus(),
               // Get ZoomVideoSDKAudioHelper to control audio
               let audioHelper = ZoomVideoSDK.shareInstance()?.getAudioHelper() {
                // Check if the user's audio type is none
                if audioStatus.audioType == .none {
                    audioHelper.startAudio()
                } else {
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
            return
        case ControlOption.shareScreen.rawValue:
            tabBar.items![ControlOption.shareScreen.rawValue].isEnabled = false

            // Get the ZoomVideoSDKShareHelper to perform UIView sharing actions.
            if let shareHelper = ZoomVideoSDK.shareInstance()?.getShareHelper() {
                // Call startSharewith: to begin sharing the loading label.
                let returnValue = shareHelper.startShare(with: loadingLabel)
                if returnValue == .Errors_Success {
                    // Your view is now being shared.
                    print("Sharing succeeded")
                } else {
                    print("Sharing failed")
                }
                
                tabBar.items![ControlOption.shareScreen.rawValue].isEnabled = true
            }

            return
        case ControlOption.endSession.rawValue:
            tabBar.isUserInteractionEnabled = false

            // Unsubscribe from sharing if currently active
            let shareCanvas = ZoomVideoSDK.shareInstance()?.getSession()?.getMySelf()?.getShareCanvas()
            if shareCanvas?.shareStatus()?.sharingStatus == ZoomVideoSDKReceiveSharingStatus.start {
                self.loadingLabel.isHidden = true
                shareCanvas?.unSubscribe(with: canvasView)
            }
            ZoomVideoSDK.shareInstance()?.leaveSession(true)
            return
        default:
            return
        }
    }
}
