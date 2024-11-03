import Foundation
import AVFoundation
import MediaPlayer
import XCDYouTubeKit

enum PlaybackError: Error {
    case audioExtractionFailed
    case invalidAudioStream
    case playerInitializationFailed
    case audioSessionError
}

class PlaybackManager: ObservableObject {
    static let shared = PlaybackManager()
    
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var duration: Double = 0
    @Published var currentTime: Double = 0
    @Published var isLoading = false
    @Published var error: PlaybackError?
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    private init() {
        setupAudioSession()
        setupRemoteTransportControls()
        setupNotifications()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetooth, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            self.error = .audioSessionError
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func play(_ song: Song) async {
        do {
            isLoading = true
            error = nil
            
            // Extract audio URL using XCDYouTubeKit
            let audioURL = try await extractAudioURL(from: song.videoID)
            
            // Create new player item and player
            let playerItem = AVPlayerItem(url: audioURL)
            
            // Wait for item to be ready to play
            let status = await withCheckedContinuation { continuation in
                var observation: NSKeyValueObservation?
                observation = playerItem.observe(\.status) { item, _ in
                    if item.status != .unknown {
                        observation?.invalidate()
                        continuation.resume(returning: item.status)
                    }
                }
            }
            
            guard status == .readyToPlay else {
                throw PlaybackError.playerInitializationFailed
            }
            
            // Update player on main thread
            await MainActor.run {
                self.player = AVPlayer(playerItem: playerItem)
                self.currentSong = song
                self.duration = playerItem.duration.seconds
                self.isPlaying = true
                self.player?.play()
                self.addTimeObserver()
                self.updateNowPlaying()
            }
            
        } catch {
            await MainActor.run {
                self.error = error as? PlaybackError ?? .audioExtractionFailed
                self.isPlaying = false
                self.isLoading = false
            }
            print("Failed to play song: \(error)")
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    private func extractAudioURL(from videoID: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let client = XCDYouTubeClient.default()
            
            client.getVideoWithIdentifier(videoID) { video, error in
                if let error = error {
                    continuation.resume(throwing: PlaybackError.audioExtractionFailed)
                    return
                }
                
                guard let video = video,
                      let streamURL = self.getBestAudioStreamURL(from: video.streamURLs) else {
                    continuation.resume(throwing: PlaybackError.invalidAudioStream)
                    return
                }
                
                continuation.resume(returning: streamURL)
            }
        }
    }
    
    private func getBestAudioStreamURL(from streamURLs: [AnyHashable: URL]) -> URL? {
        // First try to get audio-only stream
        if let audioStream = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] {
            return audioStream
        }
        
        // If no audio-only stream, get the lowest quality stream (which will be more efficient for audio)
        let qualities: [AnyHashable] = [
            XCDYouTubeVideoQualitySmall240,
            XCDYouTubeVideoQualityMedium360,
            XCDYouTubeVideoQualityHD720,
            XCDYouTubeVideoQualityHD1080
        ]
        
        for quality in qualities {
            if let streamURL = streamURLs[quality] {
                return streamURL
            }
        }
        
        return streamURLs.values.first
    }
    
    private func addTimeObserver() {
        removeTimeObserver()
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            self.progress = self.duration > 0 ? time.seconds / self.duration : 0
            self.updateNowPlaying()
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption began, pause playback
            isPlaying = false
            player?.pause()
        case .ended:
            // Interruption ended, resume playback if needed
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                isPlaying = true
                player?.play()
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones were unplugged, pause playback
            isPlaying = false
            player?.pause()
        default:
            break
        }
    }
    
    @objc private func playerItemDidReachEnd() {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.progress = 0
            self.currentTime = 0
            // Optionally play next track
        }
    }
    
    func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
        updateNowPlaying()
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time * duration, preferredTimescale: 1000)
        player?.seek(to: cmTime) { [weak self] _ in
            self?.updateNowPlaying()
        }
    }
    
    func formatTime(_ timeInSeconds: Double) -> String {
        let minutes = Int(timeInSeconds / 60)
        let seconds = Int(timeInSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayback()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayback()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: event.positionTime / self.duration)
            return .success
        }
        
        // Enable seeking using skip forward/backward buttons
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            let newTime = min(self.currentTime + 15, self.duration)
            self.seek(to: newTime / self.duration)
            return .success
        }
        
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            let newTime = max(self.currentTime - 15, 0)
            self.seek(to: newTime / self.duration)
            return .success
        }
    }
    
    private func updateNowPlaying() {
        guard let song = currentSong else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Load and set artwork asynchronously
        Task {
            if let url = URL(string: song.thumbnailURL),
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
}
