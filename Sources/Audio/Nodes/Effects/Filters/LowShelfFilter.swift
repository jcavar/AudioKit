// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
// This file was auto-autogenerated by scripts and templates at http://github.com/AudioKit/AudioKitDevTools/

import AVFoundation
import Utilities

/// AudioKit version of Apple's LowShelfFilter Audio Unit
///
public class LowShelfFilter: Node {
    public var au: AUAudioUnit

    let input: Node

    /// Connected nodes
    public var connections: [Node] { [input] }

    /// Specification details for cutoffFrequency
    public static let cutoffFrequencyDef = NodeParameterDef(
        identifier: "cutoffFrequency",
        name: "Cutoff Frequency",
        address: AUParameterAddress(kAULowShelfParam_CutoffFrequency),
        defaultValue: 80,
        range: 10 ... 200,
        unit: .hertz
    )

    /// Cutoff Frequency (Hertz) ranges from 10 to 200 (Default: 80)
    @Parameter(cutoffFrequencyDef) public var cutoffFrequency: AUValue

    /// Specification details for gain
    public static let gainDef = NodeParameterDef(
        identifier: "gain",
        name: "Gain",
        address: AUParameterAddress(kAULowShelfParam_Gain),
        defaultValue: 0,
        range: -40 ... 40,
        unit: .decibels
    )

    /// Gain (decibels) ranges from -40 to 40 (Default: 0)
    @Parameter(gainDef) public var gain: AUValue

    /// Initialize the low shelf filter node
    ///
    /// - parameter input: Input node to process
    /// - parameter cutoffFrequency: Cutoff Frequency (Hertz) ranges from 10 to 200 (Default: 80)
    /// - parameter gain: Gain (decibels) ranges from -40 to 40 (Default: 0)
    ///
    public init(
        _ input: Node,
        cutoffFrequency: AUValue = cutoffFrequencyDef.defaultValue,
        gain: AUValue = gainDef.defaultValue
    ) {
        self.input = input

        let desc = AudioComponentDescription(appleEffect: kAudioUnitSubType_LowShelfFilter)
        au = instantiateAU(componentDescription: desc)
        associateParams(with: au)

        self.cutoffFrequency = cutoffFrequency
        self.gain = gain
    }
}
