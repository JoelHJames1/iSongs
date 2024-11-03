import SwiftUI

struct MiniPlayerView: View {
    @Binding var song: Song?
    @Binding var isPlaying: Bool
    @Binding var isExpanded: Bool
    @StateObject private var playbackManager = PlaybackManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                FullScreenPlayerView(
                    song: $song,
                    isPlaying: $isPlaying,
                    isExpanded: $isExpanded
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .bottom)
                ))
            }
            
            // Mini player
            HStack(spacing: ThemeMetrics.Padding.medium) {
                // Album art
                AsyncImage(url: URL(string: song?.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(ThemeColor.secondaryText.color.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(ThemeColor.secondaryText.color)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .shadow(radius: ThemeShadow.small.radius)
                
                // Song info
                VStack(alignment: .leading) {
                    Text(song?.title ?? "Not Playing")
                        .font(ThemeFont.body())
                        .foregroundColor(ThemeColor.text.color)
                        .lineLimit(1)
                    
                    Text(song?.artist ?? "")
                        .font(ThemeFont.caption())
                        .foregroundColor(ThemeColor.secondaryText.color)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: ThemeMetrics.Padding.large) {
                    Button(action: {
                        playbackManager.togglePlayback()
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: ThemeMetrics.IconSize.medium))
                            .foregroundColor(ThemeColor.text.color)
                    }
                    
                    Button(action: {
                        // Skip to next track
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: ThemeMetrics.IconSize.medium))
                            .foregroundColor(ThemeColor.text.color)
                    }
                }
                .padding(.trailing)
            }
            .padding(.horizontal)
            .frame(height: 70)
            .background(.ultraThinMaterial)
            .onTapGesture {
                withAnimation(ThemeAnimation.standard) {
                    isExpanded = true
                }
            }
        }
    }
}

struct FullScreenPlayerView: View {
    @Binding var song: Song?
    @Binding var isPlaying: Bool
    @Binding var isExpanded: Bool
    @StateObject private var playbackManager = PlaybackManager.shared
    @State private var isLiked = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: ThemeGradient.primary),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: ThemeMetrics.Padding.large) {
                // Header
                HStack {
                    Button(action: {
                        withAnimation(ThemeAnimation.standard) {
                            isExpanded = false
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: ThemeMetrics.IconSize.medium))
                            .foregroundColor(ThemeColor.text.color)
                    }
                    
                    Spacer()
                    
                    Text("Now Playing")
                        .font(ThemeFont.headline())
                        .foregroundColor(ThemeColor.text.color)
                    
                    Spacer()
                    
                    Button(action: {
                        isLiked.toggle()
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: ThemeMetrics.IconSize.medium))
                            .foregroundColor(isLiked ? ThemeColor.error.color : ThemeColor.text.color)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Album art
                AsyncImage(url: URL(string: song?.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(ThemeColor.secondaryText.color.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: ThemeMetrics.IconSize.extraLarge))
                                .foregroundColor(ThemeColor.secondaryText.color)
                        )
                }
                .frame(width: 280, height: 280)
                .clipShape(Circle())
                .shadow(radius: ThemeShadow.large.radius)
                
                Spacer()
                
                // Song info
                VStack(spacing: ThemeMetrics.Padding.small) {
                    Text(song?.title ?? "Not Playing")
                        .font(ThemeFont.title())
                        .foregroundColor(ThemeColor.text.color)
                        .multilineTextAlignment(.center)
                    
                    Text(song?.artist ?? "")
                        .font(ThemeFont.headline())
                        .foregroundColor(ThemeColor.secondaryText.color)
                }
                .padding(.horizontal)
                
                // Progress bar
                VStack(spacing: ThemeMetrics.Padding.small) {
                    Slider(value: Binding(
                        get: { playbackManager.progress },
                        set: { playbackManager.seek(to: $0) }
                    ))
                    .accentColor(ThemeColor.accent.color)
                    
                    HStack {
                        Text(playbackManager.formatTime(playbackManager.currentTime))
                            .font(ThemeFont.caption())
                            .foregroundColor(ThemeColor.secondaryText.color)
                        Spacer()
                        Text(playbackManager.formatTime(playbackManager.duration))
                            .font(ThemeFont.caption())
                            .foregroundColor(ThemeColor.secondaryText.color)
                    }
                }
                .padding(.horizontal)
                
                // Controls
                HStack(spacing: ThemeMetrics.Padding.extraLarge) {
                    Button(action: {
                        // Previous track
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: ThemeMetrics.IconSize.large))
                            .foregroundColor(ThemeColor.text.color)
                    }
                    
                    Button(action: {
                        playbackManager.togglePlayback()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 65))
                            .foregroundColor(ThemeColor.text.color)
                    }
                    
                    Button(action: {
                        // Next track
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: ThemeMetrics.IconSize.large))
                            .foregroundColor(ThemeColor.text.color)
                    }
                }
                .padding(.vertical, ThemeMetrics.Padding.large)
                
                // Additional controls
                HStack(spacing: ThemeMetrics.Padding.extraLarge) {
                    Button(action: {
                        // Toggle shuffle
                    }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: ThemeMetrics.IconSize.medium))
                            .foregroundColor(ThemeColor.secondaryText.color)
                    }
                    
                    Button(action: {
                        // Add to playlist
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: ThemeMetrics.IconSize.medium))
                            .foregroundColor(ThemeColor.secondaryText.color)
                    }
                    
                    Button(action: {
                        // Toggle repeat
                    }) {
                        Image(systemName: "repeat")
                            .font(.system(size: ThemeMetrics.IconSize.medium))
                            .foregroundColor(ThemeColor.secondaryText.color)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
    }
}

#Preview {
    MiniPlayerView(
        song: .constant(Song(
            id: "1",
            title: "Preview Song",
            artist: "Preview Artist",
            thumbnailURL: "",
            videoID: "123"
        )),
        isPlaying: .constant(true),
        isExpanded: .constant(false)
    )
}
