import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @StateObject private var navigationManager = NavigationManager.shared
    @State private var showingCreatePlaylist = false
    @State private var showingSortOptions = false
    
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
                LazyVStack(spacing: ThemeMetrics.Padding.large) {
                    // Recently Played Section
                    if !viewModel.recentlyPlayed.isEmpty {
                        VStack(alignment: .leading, spacing: ThemeMetrics.Padding.medium) {
                            SectionHeader(
                                title: "Recently Played",
                                action: viewModel.clearRecentlyPlayed
                            )
                            
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
                    }
                    
                    // Playlists Section
                    VStack(alignment: .leading, spacing: ThemeMetrics.Padding.medium) {
                        HStack {
                            Text("Your Playlists")
                                .font(ThemeFont.title())
                                .foregroundColor(ThemeColor.text.color)
                            
                            Spacer()
                            
                            Button(action: {
                                showingSortOptions = true
                            }) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: ThemeMetrics.IconSize.medium))
                                    .foregroundColor(ThemeColor.text.color)
                            }
                            
                            Button(action: {
                                showingCreatePlaylist = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: ThemeMetrics.IconSize.medium))
                                    .foregroundColor(ThemeColor.text.color)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.playlists.isEmpty {
                            ThemeEmptyStateView(
                                icon: "music.note.list",
                                message: "No playlists yet",
                                actionTitle: "Create Playlist",
                                action: { showingCreatePlaylist = true }
                            )
                            .padding(.top, 30)
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: ThemeMetrics.Padding.medium),
                                    GridItem(.flexible(), spacing: ThemeMetrics.Padding.medium)
                                ],
                                spacing: ThemeMetrics.Padding.medium
                            ) {
                                ForEach(viewModel.playlists) { playlist in
                                    PlaylistGridItem(playlist: playlist)
                                        .onTapGesture {
                                            navigationManager.navigateToPlaylist(playlist)
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .navigationTitle("Library")
        .sheet(isPresented: $showingCreatePlaylist) {
            CreatePlaylistView(viewModel: viewModel)
        }
        .confirmationDialog("Sort Playlists", isPresented: $showingSortOptions) {
            Button("Name (A-Z)") {
                viewModel.sortPlaylists(by: .nameAscending)
            }
            Button("Name (Z-A)") {
                viewModel.sortPlaylists(by: .nameDescending)
            }
            Button("Recently Added") {
                viewModel.sortPlaylists(by: .dateAdded)
            }
            Button("Most Songs") {
                viewModel.sortPlaylists(by: .songCount)
            }
            Button("Cancel", role: .cancel) {}
        }
        .overlay {
            if viewModel.isLoading {
                ThemeLoadingView()
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(ThemeFont.title())
                .foregroundColor(ThemeColor.text.color)
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Image(systemName: "trash")
                        .font(.system(size: ThemeMetrics.IconSize.medium))
                        .foregroundColor(ThemeColor.secondaryText.color)
                }
            }
        }
        .padding(.horizontal)
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

struct PlaylistGridItem: View {
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
            .frame(height: 170)
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
    }
}

struct CreatePlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LibraryViewModel
    @State private var playlistName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColor.background.color
                    .ignoresSafeArea()
                
                VStack(spacing: ThemeMetrics.Padding.large) {
                    TextField("Playlist Name", text: $playlistName)
                        .font(ThemeFont.body())
                        .foregroundColor(ThemeColor.text.color)
                        .padding()
                        .background(ThemeColor.text.color.opacity(0.1))
                        .cornerRadius(ThemeMetrics.CornerRadius.medium)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, ThemeMetrics.Padding.large)
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createPlaylist(name: playlistName)
                        dismiss()
                    }
                    .disabled(playlistName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        LibraryView()
    }
}
