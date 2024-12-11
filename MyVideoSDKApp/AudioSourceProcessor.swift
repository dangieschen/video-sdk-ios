import UIKit
import AVFoundation
import ZoomVideoSDK

// MARK: - Audio Source Processor
class AudioSourceProcessor: NSObject, ZoomVideoSDKVirtualAudioMic {
    private let audioEngine = AVAudioEngine()
    private var currentChannel: Int = 0 // 0: Both, 1: Body (Left), 2: Room (Right)
    private var isProcessing = false
    private let bufferSize = 1024
    private var audioSender: ZoomVideoSDKAudioSender?
    
    // MARK: - ZoomVideoSDKVirtualAudioMic Methods
    func onMicInitialize(_ rawDataSender: ZoomVideoSDKAudioSender) {
        print("Virtual Microphone initialized")
        audioSender = rawDataSender
        startProcessing()
    }
    
    func onMicStartSend() {
        print("Virtual Microphone starting to send")
        isProcessing = true
    }
    
    func onMicStopSend() {
        print("Virtual Microphone stopped sending")
        isProcessing = false
    }
    
    func onMicUninitialized() {
        print("Virtual Microphone uninitialized")
        stopProcessing()
        audioSender = nil
    }
    
    // MARK: - Audio Processing
    func startProcessing() {
        setupAudioSession()
        startMicrophoneCapture()
    }
    
    func stopProcessing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isProcessing = false
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func startMicrophoneCapture() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: UInt32(bufferSize), format: format) { [weak self] buffer, time in
            self?.processBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isProcessing,
              let channelData = buffer.floatChannelData else { return }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)
        let sampleRate = UInt(buffer.format.sampleRate)
        
        // Process based on selected channel
        var processedData: [Float] = []
        
        switch currentChannel {
        case 1: // Body Mic (Left)
            if channelCount > 1 {
                // Use actual left channel
                for frame in 0..<frameCount {
                    processedData.append(channelData[0][frame])
                }
            } else {
                // Use mono channel
                for frame in 0..<frameCount {
                    processedData.append(channelData[0][frame])
                }
            }
            print("Processing Body Mic (Left Channel)")
            
        case 2: // Room Mic (Right)
            if channelCount > 1 {
                // Use actual right channel
                for frame in 0..<frameCount {
                    processedData.append(channelData[1][frame])
                }
            } else {
                // Invert mono signal for simulated right channel
                for frame in 0..<frameCount {
                    processedData.append(-channelData[0][frame])
                }
            }
            print("Processing Room Mic (Right Channel)")
            
        default: // Both channels
            if channelCount > 1 {
                // Interleave both channels
                for frame in 0..<frameCount {
                    processedData.append(channelData[0][frame])
                    processedData.append(channelData[1][frame])
                }
            } else {
                // Duplicate mono channel
                for frame in 0..<frameCount {
                    processedData.append(channelData[0][frame])
                    processedData.append(channelData[0][frame])
                }
            }
            print("Processing Both Channels")
        }
        
        // Convert to Int8 and send to Zoom
        let int8Data = processedData.withUnsafeBytes { floatBuffer -> [Int8] in
            let int8Pointer = floatBuffer.bindMemory(to: Int8.self)
            return Array(int8Pointer)
        }
        
        int8Data.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            let sendStatus = audioSender?.send(UnsafeMutablePointer(mutating: baseAddress),
                                             dataLength: UInt(int8Data.count),
                                             sampleRate: sampleRate)
            
            if let status = sendStatus {
                switch status {
                case .Errors_Success:
                    print("Successfully sent audio data")
                default:
                    print("Failed to send audio data, error: \(status)")
                }
            }
        }
    }
    
    func setChannel(_ channel: Int) {
        print("Switching to channel: \(channel)")
        currentChannel = channel
        
        // Restart audio processing with new channel
        stopProcessing()
        startProcessing()
    }
}
