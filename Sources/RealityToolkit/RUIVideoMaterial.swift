//
//  RUIVideoTexture.swift
//  
//
//  Created by Max Cobb on 14/05/2022.
//

import RealityKit
import AVKit

@available(iOS 14.0, macOS 11.0, *)
public class RUIVideoMaterial {

    private var playing = false
    public let useLooper: Bool
    public let videoSource: VideoSource

    private var player: AVPlayer?

    private var playerItem: AVPlayerItem?
    private var playerLooper: AVPlayerLooper?

    public private(set) var videoMaterial: VideoMaterial?

    private func createAVPlayer(_ named: String, withExtension ext: String) -> AVPlayer? {
        guard let url = Bundle.main.url(forResource: named, withExtension: ext) else {
            return nil
        }

        let avPlayer = AVPlayer(url: url)
        return avPlayer
    }

    private func createVideoPlayerItem() -> AVPlayerItem? {
        switch self.videoSource {
        case .file(let named, let ext):
            guard let url = Bundle.main.url(forResource: named, withExtension: ext) else {
                return nil
            }

            return AVPlayerItem(asset: AVAsset(url: url))
        case .url(let url):
            let asset = AVURLAsset(url: url)
            return AVPlayerItem(asset: asset)
        }
    }

    public enum VideoSource {
        case url(URL)
        case file(named: String, ext: String)
    }

    public init?(videoSource: VideoSource, useLooper: Bool = false) {
        self.useLooper = useLooper
        self.videoSource = videoSource
        if !self.preparePlayer() {
            return nil
        }
    }

    fileprivate func preparePlayer() -> Bool {
        let playerItem = createVideoPlayerItem()
        if useLooper {
            guard let avPlayerItem = playerItem else { return false }
            let queuePlayer = AVQueuePlayer()
            self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: avPlayerItem)
            self.playerItem = avPlayerItem
            self.player = queuePlayer
        } else {
            self.player = AVPlayer()
            self.player?.replaceCurrentItem(with: playerItem)
        }
        guard let avPlayer = self.player else { return false }
        avPlayer.actionAtItemEnd = .pause
        avPlayer.pause()
        self.videoMaterial = VideoMaterial(avPlayer: avPlayer)
        return true
    }

    public func reset() {
        guard let avPlayer = self.player else { return }
        // reset state is paused at the beginning of the video
        avPlayer.pause()
        avPlayer.seek(to: .zero)
        self.playing = false
    }

    public func sceneUpdate() {
        guard self.playing, let avPlayer = self.player else { return }
        if avPlayer.timeControlStatus == .paused {
            avPlayer.seek(to: .zero)
            avPlayer.play()
        }
    }

    public func enablePlayPause(_ enable: Bool) {
        self.playing = enable
        guard let avPlayer = self.player else { return }
        if self.playing, avPlayer.timeControlStatus == .paused {
            avPlayer.play()
        } else if !self.playing, avPlayer.timeControlStatus != .paused {
            avPlayer.pause()
        }
    }
}
