import AVFoundation

final class PhaseSoundPlayer {
    static let shared = PhaseSoundPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let buffer: AVAudioPCMBuffer?
    private let queue = DispatchQueue(label: "AMPPhaseSoundPlayer")

    private init() {
        buffer = PhaseSoundPlayer.renderJingle()
        if let buffer {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
        }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    func play() {
        guard let buffer else { return }
        queue.async { [weak self] in
            guard let self else { return }
            if !self.engine.isRunning {
                try? self.engine.start()
            }
            self.player.stop()
            self.player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            self.player.play()
        }
    }

    private static func renderJingle() -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        let notes: [(frequency: Double, duration: Double)] = [
            (523.25, 0.08),
            (659.26, 0.08),
            (783.99, 0.08),
            (1046.50, 0.10),
            (783.99, 0.10),
            (659.26, 0.10),
            (523.25, 0.18)
        ]
        let gap: Double = 0.012
        let totalSeconds = notes.reduce(0) { $0 + $1.duration + gap }
        let totalFrames = Int(totalSeconds * sampleRate)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(totalFrames)

        var frame = 0
        for note in notes {
            let noteFrames = Int(note.duration * sampleRate)
            let gapFrames = Int(gap * sampleRate)
            let period = sampleRate / note.frequency
            for i in 0..<noteFrames {
                let high = Int(Double(i) / period) % 2 == 0
                samples[frame] = high ? 0.5 : -0.5
                frame += 1
            }
            for _ in 0..<gapFrames {
                samples[frame] = 0
                frame += 1
            }
        }
        return buffer
    }
}
