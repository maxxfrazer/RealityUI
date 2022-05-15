//
//  RUIVideoTexture.swift
//  
//
//  Created by Max Cobb on 14/05/2022.
//

import RealityKit
import AVKit

@available(iOS 14.0, macOS 11.0, *)
/// RealityToolkit's RUIVideoMaterial helps you create a RealityKit VideoMaterial 🎥🎞
public class RUIVideoMaterial {

    /// If the video is currently playing.
    public var playing: Bool { self.videoState == .playing }

    /// State of the video.
    public private(set) var videoState: VideoState = .notInitialized
    /// Whether the video will loop.
    public let loops: Bool
    /// Source of the video file or stream.
    public let videoSource: VideoSource

    private var player: AVPlayer?

    private var playerItem: AVPlayerItem?
    private var playerLooper: AVPlayerLooper?

    /// Video material that can be added to a model in RealityKit
    public private(set) var videoMaterial: VideoMaterial?

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

    /// Source of the video for AVPlayer
    public enum VideoSource {
        /// URL of the local or remote video file or stream.
        case url(URL)
        /// Name and extension of a video file found in your app's bundle.
        case file(named: String, ext: String)
    }

    /// Create an RUIVideoMaterial, a wrapper for VideoMaterials in RealityKit.
    /// - Parameters:
    ///   - videoSource: Source of the video, either a local file, or a URL.
    ///   - loops: Whether the video should loop.
    public init?(videoSource: VideoSource, loops: Bool = false) {
        self.loops = loops
        self.videoSource = videoSource
        if !self.preparePlayer() {
            return nil
        }
    }

    fileprivate func preparePlayer() -> Bool {
        let playerItem = createVideoPlayerItem()
        if loops {
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
        self.videoState = .ready
        return true
    }

    /// Set video back to the start and pause.
    /// - Returns: Returns false if method fails.
    public func reset() -> Bool {
        guard let avPlayer = self.player else { return false }
        avPlayer.pause()
        avPlayer.seek(to: .zero)
        self.videoState = .ready
        return true
    }

    public func sceneUpdate() {
        guard self.playing, let avPlayer = self.player else { return }
        if avPlayer.timeControlStatus == .paused {
            avPlayer.seek(to: .zero)
            avPlayer.play()
        }
    }

    /// State of the AVPlayer and video.
    public enum VideoState {
        /// Video is not initialised, either it is being fetched still, or something is wrong with the video source.
        case notInitialized
        /// Video is at the beginning and ready to play.
        case ready
        /// Video is paused.
        case paused
        /// Video is playing.
        case playing
    }

    /// Set the state of the video, between playing and paused.
    /// - Parameter playing: Add `true` to play, `false` to pause.
    /// - Returns: Returns false if method fails.
    public func setVideoState(playing: Bool) -> Bool {
        guard let avPlayer = self.player, self.videoState != .notInitialized else { return false }
        self.videoState = playing ? .playing : .paused
        if self.videoState == .playing, avPlayer.timeControlStatus == .paused {
            avPlayer.play()
        } else if self.videoState == .paused, avPlayer.timeControlStatus != .paused {
            avPlayer.pause()
        }
        return true
    }
}
