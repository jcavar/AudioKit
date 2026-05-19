// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import AVFoundation

/// AudioKit version of Apple's TimePitch Audio Unit
///
public class TimePitch: NamedNode {
    fileprivate let timePitchAU = AVAudioUnitTimePitch()

    let input: Node

    /// Connected nodes
    public var connections: [Node] { [input] }

    /// Underlying AVAudioNode
    public var avAudioNode: AVAudioNode

    #if Swift6
    public var outputFormat: AVAudioFormat = AudioEngine.defaultAudioFormat
    #endif

    public var name = "TimePitch"

    /// Rate (rate) ranges from 0.03125 to 32.0 (Default: 1.0)
    public var rate: AUValue = 1.0 {
        didSet {
            rate = rate.clamped(to: 0.031_25 ... 32)
            timePitchAU.rate = rate
            reset()
        }
    }

    /// Pitch (Cents) ranges from -2400 to 2400 (Default: 0.0)
    public var pitch: AUValue = 0.0 {
        didSet {
            pitch = pitch.clamped(to: -2400 ... 2400)
            timePitchAU.pitch = pitch
        }
    }

    /// Overlap (generic) ranges from 3.0 to 32.0 (Default: 8.0)
    public var overlap: AUValue = 8.0 {
        didSet {
            overlap = overlap.clamped(to: 3 ... 32)
            timePitchAU.overlap = overlap
        }
    }

    /// Initialize the time pitch node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - rate: Rate (rate) ranges from 0.03125 to 32.0 (Default: 1.0)
    ///   - pitch: Pitch (Cents) ranges from -2400 to 2400 (Default: 0.0)
    ///   - overlap: Overlap (generic) ranges from 3.0 to 32.0 (Default: 8.0)
    ///
    public init(
        _ input: Node,
        rate: AUValue = 1.0,
        pitch: AUValue = 0.0,
        overlap: AUValue = 8.0
    ) {
        self.input = input
        #if Swift6
        self.outputFormat = input.outputFormat
        #endif
        self.rate = rate
        self.pitch = pitch
        self.overlap = overlap

        avAudioNode = timePitchAU
    }

    #if Swift6
    /// Initialize the time pitch node with an explicit downstream format.
    public convenience init(
        _ input: Node,
        rate: AUValue = 1.0,
        pitch: AUValue = 0.0,
        overlap: AUValue = 8.0,
        outputFormat: AVAudioFormat
    ) {
        self.init(input, rate: rate, pitch: pitch, overlap: overlap)
        self.outputFormat = outputFormat
    }
    #endif
}
