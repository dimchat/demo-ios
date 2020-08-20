//
//  RecordingTool.swift
//  hxjh
//
//  Created by huihua xiao on 2019/6/24.
//  Copyright © 2019 GanGuo. All rights reserved.
//

import UIKit
import AVFoundation

class RecordingTool: NSObject {
    static let shared = RecordingTool()
    private var timer: Timer!
    private var recordFilePath: String!
    private var mp3FilePath: String!
    private var recorder: AVAudioRecorder!
    private var session: AVAudioSession!

    func startRecording(timeBlock: IntBlock?) {
        session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { [weak self](granted) in
            guard let strongSelf = self else { return }

            if granted {
                strongSelf.recordFilePath = NSTemporaryDirectory() + "record.caf"
                // 设置后台播放,下面这段是录音和播放录音的设置
                do {
                    try strongSelf.session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default)
                    try strongSelf.session.setActive(true)
                } catch let error {
                    print(error.localizedDescription)
                }
                if strongSelf.recorder == nil {
                    /*
                     * settings 参数
                     1.AVNumberOfChannelsKey 通道数 通常为双声道 值2
                     2.AVSampleRateKey 采样率 单位HZ 通常设置成44100 也就是44.1k,采样率必须要设为11025才能使转化成mp3格式后不会失真
                     3.AVLinearPCMBitDepthKey 比特率 8 16 24 32
                     4.AVEncoderAudioQualityKey 声音质量
                     ① AVAudioQualityMin  = 0, 最小的质量
                     ② AVAudioQualityLow  = 0x20, 比较低的质量
                     ③ AVAudioQualityMedium = 0x40, 中间的质量
                     ④ AVAudioQualityHigh  = 0x60,高的质量
                     ⑤ AVAudioQualityMax  = 0x7F 最好的质量
                     5.AVEncoderBitRateKey 音频编码的比特率 单位Kbps 传输的速率 一般设置128000 也就是128kbps
                     */
                    let settings = [AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM),
                                    AVSampleRateKey: NSNumber(value: 11025.0),
                                    AVNumberOfChannelsKey: NSNumber(value: 2),
                                    AVEncoderBitDepthHintKey: NSNumber(value: 16),
                                    AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.high.rawValue)] as [String: Any]
                    // 开始录音,将所获取到得录音存到文件里
                    let recordUrl = URL(fileURLWithPath: strongSelf.recordFilePath ?? "")
                    do {
                        strongSelf.recorder = try AVAudioRecorder(url: recordUrl, settings: settings)
                        strongSelf.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                            timeBlock?(strongSelf.recorder.currentTime.int)
                        })
                        // 准备记录录音
                        strongSelf.recorder.prepareToRecord()
                        // 开启仪表计数功能,必须开启这个功能，才能检测音频值
                        strongSelf.recorder.isMeteringEnabled = true
                        // 启动或者恢复记录的录音文件
                        if !(strongSelf.recorder.isRecording ) {
                            strongSelf.recorder.record()
                        }
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            } else {
                let alertCtrl = UIAlertController(title: "麦克风不可用", message: "请在“设置-隐私-麦克风”中允许App访问您的麦克风", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "好的", style: .default, handler: nil)
                alertCtrl.addAction(okAction)
                UIViewController.current?.fullPresent(alertCtrl)
            }
        }
    }

    func pauseRecording(isNeedFilePath: Bool = false) -> (Data?, String?) {
        if recorder == nil {
            return (nil, nil)
        }
        recorder.stop()
        recorder = nil
        invalidateTimer()
        do {
            try session.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
            try session.setActive(false)
        } catch {
            print("麦克风停止出错")
        }
        do {

            let dict = TransformMP3.transformCAF(toMP3: recordFilePath)
            mp3FilePath = dict?["filePath"] as? String ?? ""
            deleteFile(path: recordFilePath)
            if isNeedFilePath {
                return (nil, mp3FilePath)
            }
            let mp3Data = try Data(contentsOf: URL(fileURLWithPath: mp3FilePath))
            deleteFile(path: mp3FilePath)
            return (mp3Data, nil)
        } catch {
            print("TransformMP3出错")
        }
        return (nil, nil)
    }

    func cancelRecording() {
        if recorder == nil {
            return
        }
        invalidateTimer()
        recorder.stop()
        recorder = nil
        try? session.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
        try? session.setActive(false)
        deleteFile(path: recordFilePath)
    }

    func deleteRecordFile() {
        deleteFile(path: recordFilePath ?? "")
        deleteFile(path: mp3FilePath ?? "")
    }

    private func deleteFile(path: String) {
        if path == "" { return }
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}
