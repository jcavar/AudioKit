// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
// This file was auto-autogenerated by scripts and templates at http://github.com/AudioKit/AudioKitDevTools/

import AVFoundation
import Utilities

/// AudioKit version of Apple's LowPassFilter Audio Unit
///
public class LowPassFilter: Node {
    public var au: AUAudioUnit

    let input: Node

    /// Connected nodes
    public var connections: [Node] { [input] }

    /// Specification details for cutoffFrequency
    public static let cutoffFrequencyDef = NodeParameterDef(
        identifier: "cutoffFrequency",
        name: "Cutoff Frequency",
        address: AUParameterAddress(kLowPassParam_CutoffFrequency),
        defaultValue: 6900,
        range: 10 ... 22050,
        unit: .hertz
    )

    /// Cutoff Frequency (Hertz) ranges from 10 to 22050 (Default: 6900)
    @Parameter(cutoffFrequencyDef) public var cutoffFrequency: AUValue

    /// Specification details for resonance
    public static let resonanceDef = NodeParameterDef(
        identifier: "resonance",
        name: "Resonance",
        address: AUParameterAddress(kLowPassParam_Resonance),
        defaultValue: 0,
        range: -20 ... 40,
        unit: .decibels
    )

    /// Resonance (decibels) ranges from -20 to 40 (Default: 0)
    @Parameter(resonanceDef) public var resonance: AUValue

    /// Initialize the low pass filter node
    ///
    /// - parameter input: Input node to process
    /// - parameter cutoffFrequency: Cutoff Frequency (Hertz) ranges from 10 to 22050 (Default: 6900)
    /// - parameter resonance: Resonance (decibels) ranges from -20 to 40 (Default: 0)
    ///
    public init(
        _ input: Node,
        cutoffFrequency: AUValue = cutoffFrequencyDef.defaultValue,
        resonance: AUValue = resonanceDef.defaultValue
    ) {
        self.input = input

        let desc = AudioComponentDescription(appleEffect: kAudioUnitSubType_LowPassFilter)
        au = instantiateAU(componentDescription: desc)
        associateParams(with: au)

        self.cutoffFrequency = cutoffFrequency
        self.resonance = resonance
    }
}
