import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var navigationManager = NavigationManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: ThemeGradient.primary),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: ThemeMetrics.Padding.extraLarge) {
                    // Welcome Message
                    WelcomeHeader(userName: viewModel.displayName)
                    
                    // Recently Played Section
                    if !viewModel.recentlyPlayed.isEmpty {
                        HomeSectionView(
                            title: "Recently Played",
                            showAll: false,
                            content: {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: ThemeMetrics.Padding.medium) {
                                        ForEach(viewModel.recentlyPlayed) { song in
                                            RecentlyPlayedCard(song: song)
                                                .onTapGesture {
                                                    viewModel.playSong(song)
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        )
                    }
                    
                    // Popular Songs Section
                    if !viewModel.popularSongs.isEmpty {
                        HomeSectionView(
                            title: "Popular Songs",
                            showAll: true,
                            onTapShowAll: {
                                navigationManager.navigateToSearch()
                            },
                            content: {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: ThemeMetrics.Padding.medium) {
                                        ForEach(viewModel.popularSongs) { song in
                                            PopularSongCard(song: song)
                                                .onTapGesture {
                                                    viewModel.playSong(song)
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        )
                    }
                    
                    // Your Playlists Section
                    if !viewModel.userPlaylists.isEmpty {
                        HomeSectionView(
                            title: "Your Playlists",
                            showAll: true,
                            onTapShowAll: {
                                navigationManager.navigateToLibrary()
                            },
                            content: {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: ThemeMetrics.Padding.medium) {
                                        ForEach(viewModel.userPlaylists) { playlist in
                                            PlaylistCard(playlist: playlist)
                                                .onTapGesture {
                                                    navigationManager.navigateToPlaylist(playlist)
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, ThemeMetrics.Padding.large)
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .overlay {
            if viewModel.isLoading {
                ThemeLoadingView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK", role: .cancel) {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

struct WelcomeHeader: View {
    let userName: String?
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ThemeMetrics.Padding.small) {
            Text(greeting)
                .font(ThemeFont.headline())
                .foregroundColor(ThemeColor.secondaryText.color)
            
            Text(userName ?? "Music Lover")
                .font(ThemeFont.title(.large))
                .foregroundColor(ThemeColor.text.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

struct HomeSectionView<Content: View>: View {
    let title: String
    let showAll: Bool
    var onTapShowAll: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: ThemeMetrics.Padding.medium) {
            HStack {
                Text(title)
                    .font(ThemeFont.title())
                    .foregroundColor(ThemeColor.text.color)
                
                Spacer()
                
                if showAll {
                    Button(action: { onTapShowAll?() }) {
                        Text("See All")
                            .font(ThemeFont.body())
                            .foregroundColor(ThemeColor.accent.color)
                    }
                }
            }
            .padding(.horizontal)
            
            content()
        }
    }
}

struct RecentlyPlayedCard: View {
    let song: Song
    
    var body: some View {
        VStack(alignment: .leading, spacing: ThemeMetrics.Padding.small) {
            AsyncImage(url: URL(string: song.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(ThemeColor.secondaryText.color.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: ThemeMetrics.IconSize.large))
                            .foregroundColor(ThemeColor.secondaryText.color)
                    )
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: ThemeMetrics.CornerRadius.medium))
            .shadow(radius: ThemeShadow.medium.radius)
            
            Text(song.title)
                .font(ThemeFont.body())
                .foregroundColor(ThemeColor.text.color)
                .lineLimit(2)
            
            Text(song.artist)
                .font(ThemeFont.caption())
                .foregroundColor(ThemeColor.secondaryText.color)
                .lineLimit(1)
        }
        .frame(width: 150)
    }
}

struct PopularSongCard: View {
    let song: Song
    
    var body: some View {
        VStack(alignment: .leading, spacing: ThemeMetrics.Padding.small) {
            AsyncImage(url: URL(string: song.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(ThemeColor.secondaryText.color.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: ThemeMetrics.IconSize.large))
                            .foregroundColor(ThemeColor.secondaryText.color)
                    )
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: ThemeMetrics.CornerRadius.medium))
            .shadow(radius: ThemeShadow.medium.radius)
            
            Text(song.title)
                .font(ThemeFont.body())
                .foregroundColor(ThemeColor.text.color)
                .lineLimit(2)
            
            Text(song.artist)
                .font(ThemeFont.caption())
                .foregroundColor(ThemeColor.secondaryText.color)
                .lineLimit(1)
        }
        .frame(width: 150)
    }
}

struct PlaylistCard: View {
    let playlist: Playlist
    
    var body: some View {
        VStack(alignment: .leading, spacing: ThemeMetrics.Padding.small) {
            ZStack {
                if let firstSong = playlist.songs.first {
                    AsyncImage(url: URL(string: firstSong.thumbnailURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(ThemeColor.secondaryText.color.opacity(0.3))
                    }
                } else {
                    Rectangle()
                        .fill(ThemeColor.secondaryText.color.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.system(size: ThemeMetrics.IconSize.large))
                                .foregroundColor(ThemeColor.secondaryText.color)
                        )
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: ThemeMetrics.CornerRadius.medium))
            .shadow(radius: ThemeShadow.medium.radius)
            
            Text(playlist.name)
                .font(ThemeFont.body())
                .foregroundColor(ThemeColor.text.color)
                .lineLimit(1)
            
            Text("\(playlist.songs.count) songs")
                .font(ThemeFont.caption())
                .foregroundColor(ThemeColor.secondaryText.color)
        }
        .frame(width: 150)
    }
}

#Preview {
    NavigationView {
        HomeView()
    }
}
