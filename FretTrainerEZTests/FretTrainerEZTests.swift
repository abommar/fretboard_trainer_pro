import XCTest
import AVFoundation
@testable import FretTrainerEZ

final class FretTrainerEZTests: XCTestCase {

    let fretboard = Fretboard()

    // MARK: - Open strings (standard tuning: E A D G B E, index 0=low)
    func testOpenStrings() {
        XCTAssertEqual(fretboard.note(string: 0, fret: 0), .E) // low E
        XCTAssertEqual(fretboard.note(string: 1, fret: 0), .A)
        XCTAssertEqual(fretboard.note(string: 2, fret: 0), .D)
        XCTAssertEqual(fretboard.note(string: 3, fret: 0), .G)
        XCTAssertEqual(fretboard.note(string: 4, fret: 0), .B)
        XCTAssertEqual(fretboard.note(string: 5, fret: 0), .E) // high E
    }

    // MARK: - Known reference points (guitar convention: string 6 = index 0)
    func testKnownPositions() {
        // string 6 fret 5 = A
        XCTAssertEqual(fretboard.note(string: 0, fret: 5), .A)
        // string 5 fret 7 = E
        XCTAssertEqual(fretboard.note(string: 1, fret: 7), .E)
        // string 1 fret 12 = E (high)
        XCTAssertEqual(fretboard.note(string: 5, fret: 12), .E)
        // string 3 in guitar convention = D string (index 2), fret 2 = E
        // Let me recalculate: D + 2 semitones = E. But the spec says string 3 fret 2 = A.
        // Guitar string 3 (1-based from high e) = G string? No, standard notation:
        // String 6 = low E, String 5 = A, String 4 = D, String 3 = G, String 2 = B, String 1 = high E
        // So string 3 = G (index 3 in our 0-based array). G + 2 semitones = A. That matches.
        XCTAssertEqual(fretboard.note(string: 3, fret: 2), .A) // G string fret 2 = A
    }

    // MARK: - 12th fret octave rule
    func testTwelfthFretOctave() {
        for s in 0..<6 {
            XCTAssertEqual(
                fretboard.note(string: s, fret: 12),
                fretboard.note(string: s, fret: 0),
                "String \(s): fret 12 should equal open note"
            )
        }
    }

    // MARK: - allPositions count for G across 22 frets
    func testAllPositionsForG() {
        let positions = fretboard.allPositions(for: .G)
        // G appears every 12 frets on each string. With 22 frets (frets 0-22 = 23 positions):
        // Each string has either 1 or 2 G positions depending on the open note offset.
        // Let's just verify it's a reasonable non-zero number and test specific known ones.
        XCTAssertGreaterThan(positions.count, 0)
        // G string (index 3) open = G, so frets 0 and 12 are G
        XCTAssertTrue(positions.contains(where: { $0.string == 3 && $0.fret == 0 }))
        XCTAssertTrue(positions.contains(where: { $0.string == 3 && $0.fret == 12 }))
        // All 6 strings have at least one G in 22 frets
        for s in 0..<6 {
            XCTAssertTrue(positions.contains(where: { $0.string == s }), "String \(s) should have at least one G")
        }
    }
}

// MARK: - Chromatic Tuner Tests

final class PitchDetectorTests: XCTestCase {

    private let sampleRate: Float = 44100
    private let bufferSize = 4096

    /// Synthesizes a pure sine wave at the given frequency.
    private func sine(frequency: Float, amplitude: Float = 0.5) -> [Float] {
        (0..<bufferSize).map { i in
            amplitude * sin(2 * Float.pi * frequency * Float(i) / sampleRate)
        }
    }

    /// Silence buffer (all zeros).
    private func silence() -> [Float] {
        [Float](repeating: 0, count: bufferSize)
    }

    // MARK: Frequency detection — open guitar strings (standard tuning)

    // Accuracy of ±5 Hz — well within one semitone at all guitar frequencies,
    // and tighter than what a human ear can reliably distinguish for tuning.
    private let freqAccuracy: Float = 5.0

    func testDetectsE2_LowEString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 82.41), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 82.41, accuracy: freqAccuracy, "Low E string (E2) should detect near 82.41 Hz")
    }

    func testDetectsA2_AString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 110.0), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 110.0, accuracy: freqAccuracy, "A string (A2) should detect near 110 Hz")
    }

    func testDetectsD3_DString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 146.83), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 146.83, accuracy: freqAccuracy, "D string (D3) should detect near 146.83 Hz")
    }

    func testDetectsG3_GString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 196.0), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 196.0, accuracy: freqAccuracy, "G string (G3) should detect near 196 Hz")
    }

    func testDetectsB3_BString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 246.94), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 246.94, accuracy: freqAccuracy, "B string (B3) should detect near 246.94 Hz")
    }

    func testDetectsE4_HighEString() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 329.63), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 329.63, accuracy: freqAccuracy, "High E string (E4) should detect near 329.63 Hz")
    }

    func testDetectsA4_ConcertPitch() {
        let freq = PitchDetector.detectPitch(samples: sine(frequency: 440.0), sampleRate: sampleRate)
        XCTAssertNotNil(freq)
        XCTAssertEqual(freq!, 440.0, accuracy: freqAccuracy, "Concert A (A4) should detect near 440 Hz")
    }

    // MARK: Silence / low signal rejected

    func testSilenceReturnsNil() {
        XCTAssertNil(PitchDetector.detectPitch(samples: silence(), sampleRate: sampleRate),
                     "Silence should return nil")
    }

    func testVeryQuietSignalReturnsNil() {
        let quiet = sine(frequency: 440.0, amplitude: 0.005)
        XCTAssertNil(PitchDetector.detectPitch(samples: quiet, sampleRate: sampleRate),
                     "Signal below RMS threshold should return nil")
    }

    // MARK: Note name mapping

    func testNoteInfoA440() {
        let info = PitchDetector.noteInfo(frequency: 440.0)
        XCTAssertNotNil(info)
        XCTAssertEqual(info!.note, "A")
        XCTAssertEqual(info!.cents, 0.0, accuracy: 1.0)
    }

    func testNoteInfoC4_MiddleC() {
        let info = PitchDetector.noteInfo(frequency: 261.63)
        XCTAssertNotNil(info)
        XCTAssertEqual(info!.note, "C")
        XCTAssertEqual(info!.cents, 0.0, accuracy: 2.0)
    }

    func testNoteInfoSharpNote() {
        // 450 Hz is A but sharp
        let info = PitchDetector.noteInfo(frequency: 450.0)
        XCTAssertNotNil(info)
        XCTAssertEqual(info!.note, "A")
        XCTAssertGreaterThan(info!.cents, 0, "450 Hz should be sharp of A")
    }

    func testNoteInfoFlatNote() {
        // 430 Hz is A but flat
        let info = PitchDetector.noteInfo(frequency: 430.0)
        XCTAssertNotNil(info)
        XCTAssertEqual(info!.note, "A")
        XCTAssertLessThan(info!.cents, 0, "430 Hz should be flat of A")
    }

    func testNoteInfoInvalidFrequency() {
        XCTAssertNil(PitchDetector.noteInfo(frequency: 0))
        XCTAssertNil(PitchDetector.noteInfo(frequency: -100))
        XCTAssertNil(PitchDetector.noteInfo(frequency: .nan))
        XCTAssertNil(PitchDetector.noteInfo(frequency: .infinity))
    }

    // MARK: End-to-end: sine wave → note name

    func testEndToEndOpenStrings() {
        // Each open string frequency should map to the correct note name
        let expectations: [(Float, String)] = [
            (82.41,  "E"),  // low E
            (110.0,  "A"),  // A
            (146.83, "D"),  // D
            (196.0,  "G"),  // G
            (246.94, "B"),  // B
            (329.63, "E"),  // high E
        ]
        for (freq, expectedNote) in expectations {
            let buf = sine(frequency: freq)
            guard let detectedFreq = PitchDetector.detectPitch(samples: buf, sampleRate: sampleRate),
                  let info = PitchDetector.noteInfo(frequency: detectedFreq) else {
                XCTFail("Failed to detect pitch for \(freq) Hz (\(expectedNote))")
                continue
            }
            XCTAssertEqual(info.note, expectedNote,
                           "\(freq) Hz should map to \(expectedNote), got \(info.note)")
        }
    }
}
