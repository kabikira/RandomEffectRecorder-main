//
//  AudioRecorder.swift
//  RandomEffectsRecorder
//
//  Created by koala panda on 2022/11/29.
//

import Foundation
import AVFoundation
import Combine
import UIKit


class AudioRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    
    var audioRecorder: AVAudioRecorder!
    
    var recDate: Date!

    var playerNode: AVAudioPlayerNode!

    let engine = AVAudioEngine()
    
    var audioPlayer = AVAudioPlayer()
    
    let objectWillChange = PassthroughSubject<AudioRecorder, Never>()
    
    var isPlaying = false {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send(self)
            }
            
        }
    }


    func dateToString(dateValue: Date) -> String{
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .medium
        return String(df.string(from: dateValue))
    }

    //Audio File Writing Function
    func getAudioFileUrl() -> URL {
        guard let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("File URL get error")
        }
        let audioUrl = paths.appendingPathComponent("\(dateToString(dateValue: recDate)).caf")
        
        return audioUrl
    }
    
    func record() {
        recDate = Date()
        
        // Random to determine the order in which effectors are applied.
        let number = Int.random(in: 0...5)
        
        
        do {
            // 入力ノードのフォーマットを取得
            let inputNode = engine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)

            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: inputFormat.sampleRate, channels: inputFormat.channelCount, interleaved: true)
            print(inputFormat.sampleRate)

            let audioFile = try AVAudioFile(forWriting: getAudioFileUrl(), settings: format!.settings)

            
            let delayNode = AVAudioUnitDelay()
            delayNode.delayTime = Float64.random(in: 0.1...2)
            delayNode.feedback = Float.random(in: -100...100)
            delayNode.wetDryMix = Float.random(in: 0...100)
            engine.attach(delayNode)
            
            
            let distortionNode = AVAudioUnitDistortion()
            distortionNode.loadFactoryPreset(AVAudioUnitDistortionPreset(rawValue: Int.random(in: 0...17))!)
            distortionNode.wetDryMix = Float.random(in: 0...100)
            distortionNode.preGain = -6
            engine.attach(distortionNode)
            
            let reverbNode = AVAudioUnitReverb()
            reverbNode.loadFactoryPreset(AVAudioUnitReverbPreset(rawValue: Int.random(in: 0...12))!)
            reverbNode.wetDryMix = Float.random(in: 0...100)
            engine.attach(reverbNode)
            
            var node1: AVAudioNode = delayNode
            var node2: AVAudioNode = reverbNode
            var node3: AVAudioNode = distortionNode
            
            switch number {
            case 0:
                node1 = delayNode
                node2 = reverbNode
                node3 = distortionNode
                print(number, node1, node2, node3)
            case 1:
                node1 = delayNode
                node2 = distortionNode
                node3 = reverbNode
                print(number, node1, node2, node3)
            case 2:
                node1 = reverbNode
                node2 = delayNode
                node3 = distortionNode
                print(number, node1, node2, node3)
            case 3:
                node1 = reverbNode
                node2 = distortionNode
                node3 = delayNode
                print(number, node1, node2, node3)
            case 4:
                node1 = distortionNode
                node2 = reverbNode
                node3 = delayNode
                print(number, node1, node2, node3)
            case 5:
                node1 = distortionNode
                node2 = delayNode
                node3 = reverbNode
                print(number, node1, node2, node3)
            default:
                break
            }

            engine.connect(inputNode, to: node1, format: format)
            engine.connect(node1, to: node2, format: format)
            engine.connect(node2, to: node3, format: format)
            
            // Install taps on output buses
            node3.installTap(onBus: 0, bufferSize: 4096, format: format) { (buffer, when) in
                do {
                    try audioFile.write(from: buffer)
                } catch let error {
                    print("audioFile.writeFromBuffer error:", error)
                }
            }
            
            do {

                try engine.start()
            } catch let error {
                print("engine.start error:", error)
            }
        } catch let error {
            print("AVAudioFile error:", error)
        }
    }
    
    func recStop() {
        engine.stop()
    }
    
    func playSound(audio: URL) {
        do {
            // Set the audio session category, mode, and options.
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true)

            // Override the audio output to speaker. This may help increase volume.
            try audioSession.overrideOutputAudioPort(.speaker)

            audioPlayer = try AVAudioPlayer(contentsOf: audio)
            // load music into buffer
            audioPlayer.prepareToPlay()
            audioPlayer.delegate = self
            // 音量
            audioPlayer.volume = 1.0

            audioPlayer.play()
            isPlaying = true

        } catch {
            print(error,"playSound")
        }
    }
    func stopSound() {
        audioPlayer.stop()
        isPlaying = false
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Did finish Playing")
        isPlaying = false
    }
    
    
}

