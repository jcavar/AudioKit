// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import AVFoundation

public class AudioEngine2 {
    
    /// Internal AVAudioEngine
    public let avEngine = AVAudioEngine()
    
    public var output: Node? {
        didSet {
            engineAU.output = output
        }
    }
    
    var engineAU: EngineAudioUnit
    var avAudioUnit: AVAudioUnit

    // maximum number of frames the engine will be asked to render in any single render call
    let maximumFrameCount: AVAudioFrameCount = 1024
    
    public init() {
        
        let componentDescription = AudioComponentDescription(effect: "akau")
        
        AUAudioUnit.registerSubclass(EngineAudioUnit.self,
                                     as: componentDescription,
                                     name: "engine AU",
                                     version: .max)
        
        avAudioUnit = instantiate(componentDescription: componentDescription)
        engineAU = avAudioUnit.auAudioUnit as! EngineAudioUnit
        
        avEngine.attach(avAudioUnit)
        avEngine.connect(avEngine.inputNode, to: avAudioUnit, format: nil)
        avEngine.connect(avAudioUnit, to: avEngine.mainMixerNode, format: nil)
    }
    
    /// Start the engine
    public func start() throws {
        try avEngine.start()
    }
    
    /// Stop the engine
    public func stop() {
        avEngine.stop()
    }

    /// Pause the engine
    public func pause() {
        avEngine.pause()
    }

    /// Start testing for a specified total duration
    /// - Parameter duration: Total duration of the entire test
    /// - Returns: A buffer which you can append to
    public func startTest(totalDuration duration: Double) -> AVAudioPCMBuffer {
        let samples = Int(duration * Settings.sampleRate)

        do {
            avEngine.reset()
            try avEngine.enableManualRenderingMode(.offline,
                                                   format: Settings.audioFormat,
                                                   maximumFrameCount: maximumFrameCount)
            try start()
        } catch let err {
            Log("🛑 Start Test Error: \(err)")
        }

        return AVAudioPCMBuffer(
            pcmFormat: avEngine.manualRenderingFormat,
            frameCapacity: AVAudioFrameCount(samples)
        )!
    }

    /// Render audio for a specific duration
    /// - Parameter duration: Length of time to render for
    /// - Returns: Buffer of rendered audio
    public func render(duration: Double) -> AVAudioPCMBuffer {
        let sampleCount = Int(duration * Settings.sampleRate)
        let startSampleCount = Int(avEngine.manualRenderingSampleTime)

        let buffer = AVAudioPCMBuffer(
            pcmFormat: avEngine.manualRenderingFormat,
            frameCapacity: AVAudioFrameCount(sampleCount)
        )!

        let tempBuffer = AVAudioPCMBuffer(
            pcmFormat: avEngine.manualRenderingFormat,
            frameCapacity: AVAudioFrameCount(maximumFrameCount)
        )!

        do {
            while avEngine.manualRenderingSampleTime < sampleCount + startSampleCount {
                let currentSampleCount = Int(avEngine.manualRenderingSampleTime)
                let framesToRender = min(UInt32(sampleCount + startSampleCount - currentSampleCount), maximumFrameCount)
                try avEngine.renderOffline(AVAudioFrameCount(framesToRender), to: tempBuffer)
                buffer.append(tempBuffer)
            }
        } catch let err {
            Log("🛑 Could not render offline \(err)")
        }
        return buffer
    }

}