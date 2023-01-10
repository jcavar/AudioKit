// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
// This file was auto-autogenerated by scripts and templates at http://github.com/AudioKit/AudioKitDevTools/

import AVFoundation
import Utilities

/// AudioKit version of Apple's ParametricEQ Audio Unit
///
public class ParametricEQ: Node {
    public var au: AUAudioUnit

    let input: Node

    /// Connected nodes
    public var connections: [Node] { [input] }

    /// Specification details for centerFreq
    public static let centerFreqDef = NodeParameterDef(
        identifier: "centerFreq",
        name: "Center Freq",
        address: AUParameterAddress(kParametricEQParam_CenterFreq),
        defaultValue: 2000,
        range: 20 ... 22050,
        unit: .hertz
    )

    /// Center Freq (Hertz) ranges from 20 to 22050 (Default: 2000)
    @Parameter(centerFreqDef) public var centerFreq: AUValue

    /// Specification details for q
    public static let qDef = NodeParameterDef(
        identifier: "q",
        name: "Q",
        address: AUParameterAddress(kParametricEQParam_Q),
        defaultValue: 1.0,
        range: 0.1 ... 20,
        unit: .hertz
    )

    /// Q (Hertz) ranges from 0.1 to 20 (Default: 1.0)
    @Parameter(qDef) public var q: AUValue

    /// Specification details for gain
    public static let gainDef = NodeParameterDef(
        identifier: "gain",
        name: "Gain",
        address: AUParameterAddress(kParametricEQParam_Gain),
        defaultValue: 0,
        range: -20 ... 20,
        unit: .decibels
    )

    /// Gain (decibels) ranges from -20 to 20 (Default: 0)
    @Parameter(gainDef) public var gain: AUValue

    /// Initialize the parametric eq node
    ///
    /// - parameter input: Input node to process
    /// - parameter centerFreq: Center Freq (Hertz) ranges from 20 to 22050 (Default: 2000)
    /// - parameter q: Q (Hertz) ranges from 0.1 to 20 (Default: 1.0)
    /// - parameter gain: Gain (decibels) ranges from -20 to 20 (Default: 0)
    ///
    public init(
        _ input: Node,
        centerFreq: AUValue = centerFreqDef.defaultValue,
        q: AUValue = qDef.defaultValue,
        gain: AUValue = gainDef.defaultValue
    ) {
        self.input = input

        let desc = AudioComponentDescription(appleEffect: kAudioUnitSubType_ParametricEQ)
        au = instantiateAU(componentDescription: desc)
        associateParams(with: au)

        self.centerFreq = centerFreq
        self.q = q
        self.gain = gain
    }
}
