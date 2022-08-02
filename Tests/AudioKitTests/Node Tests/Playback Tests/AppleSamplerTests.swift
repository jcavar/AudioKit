// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import AudioKit
import XCTest
import AVFoundation

// Commented out these tests due to intermittent failure on CI

class AppleSamplerTests: XCTestCase {
    var audioFile: AVAudioFile!
    let sampler = AppleSampler()
    let engine = AudioEngine()

    override func setUpWithError() throws {
        let sampleURL = Bundle.module.url(forResource: "TestResources/sinechirp", withExtension: "wav")!
        audioFile = try AVAudioFile(forReading: sampleURL)
        try sampler.loadAudioFile(audioFile)
        engine.output = sampler
    }

    func testSamplePlayback() {
        let audio = engine.startTest(totalDuration: 2.0)
        sampler.play(noteNumber: 50, velocity: 127, channel: 1)
        audio.append(engine.render(duration: 2.0))
        testMD5(audio)
    }

    @available(iOS 13.0, *)
    func testSamplerNotCleanedWhenStillConnected() throws {
        func assertSamplerNotCleanedUp() {
            // When sampler gets cleaned up, it gets the default preset with sine wave
            let fileReferences = sampler.internalAU?.fullState?["file-references"] as? NSDictionary
            XCTAssertEqual(fileReferences?.count, 1)
        }
        let engine = AudioEngine()
        let sampler = AppleSampler()
        try sampler.loadAudioFile(audioFile)
        assertSamplerNotCleanedUp()

        let input = Reverb(sampler)
        let mixer = Mixer(sampler, input)
        engine.output = mixer
        _ = engine.startTest(totalDuration: 2.0)

        mixer.removeInput(input, strategy: .disconnect)

        assertSamplerNotCleanedUp()
    }

    func testStop() {
        let audio = engine.startTest(totalDuration: 3.0)
        sampler.play()
        audio.append(engine.render(duration: 1.0))
        sampler.stop()
        audio.append(engine.render(duration: 1.0))
        sampler.play()
        audio.append(engine.render(duration: 1.0))
        testMD5(audio)
    }

    func testVolume() {
        sampler.volume = 0.8
        let audio = engine.startTest(totalDuration: 2.0)
        sampler.play(noteNumber: 50, velocity: 127, channel: 1)
        audio.append(engine.render(duration: 2.0))
        testMD5(audio)
    }

    func testPan() {
        sampler.pan = 1.0
        let audio = engine.startTest(totalDuration: 2.0)
        sampler.play(noteNumber: 50, velocity: 127, channel: 1)
        audio.append(engine.render(duration: 2.0))
        testMD5(audio)
    }

    func testAmplitude() {
        sampler.amplitude = 12
        let audio = engine.startTest(totalDuration: 2.0)
        sampler.play(noteNumber: 50, velocity: 127, channel: 1)
        audio.append(engine.render(duration: 2.0))
        testMD5(audio)
    }

    // Repro case.
    /*
    func testLoadEXS24_bug() throws {
        let engine = AVAudioEngine()
        let samplerUnit = AVAudioUnitSampler()
        engine.attach(samplerUnit)
        let exsURL = Bundle.module.url(forResource: "TestResources/Sampler Instruments/sawPiano1", withExtension: "exs")!
        try samplerUnit.loadInstrument(at: exsURL)
    }
    */
}
