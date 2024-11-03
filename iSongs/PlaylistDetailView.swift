import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PlaylistDetailView: View {
    @StateObject private var viewModel: PlaylistDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingOptions = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditName = false
    @State private var editedName = ""
    @State private var showingAddSongs = false
    
    init(playlist: Playlist) {
        _viewModel = StateObject(wrappedValue: PlaylistDetailViewModel(playlist: playlist))
    }
    
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
                VStack(spacing: ThemeMetrics.Padding.large) {
                    // Playlist Header
                    PlaylistHeaderView(
                        playlist: viewModel.playlist,
                        onPlay: { viewModel.playPlaylist() },
                        onShuffle: { viewModel.shufflePlaylist() }
                    )
                    .padding(.horizontal)
                    
                    // Songs List
                    if viewModel.playlist.songs.isEmpty {
                        ThemeEmptyStateView(
                            icon: "music.note.list",
                            message: "No songs in playlist",
                            actionTitle: "Add Songs",
                            action: { showingAddSongs = true }
                        )
                        .padding(.top, 50)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.playlist.songs.enumerated()), id: \.element.id) { index, song in
                                PlaylistSongRow(
                                    song: song,
                                    index: index + 1,
                                    isPlaying: viewModel.currentlyPlayingSongId == song.id,
                                    onPlay: { viewModel.playSong(song) },
                                    onRemove: { viewModel.removeSong(song) }
                                )
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.removeSong(song)
                                    } label: {
                                        Label("Remove from Playlist", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        // Add to queue
                                        viewModel.addToQueue(song)
                                    } label: {
                                        Label("Add to Queue", systemImage: "text.badge.plus")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(viewModel.playlist.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: ThemeMetrics.IconSize.medium))
                        .foregroundColor(ThemeColor.text.color)
                }
            }
        }
        .confirmationDialog("Playlist Options", isPresented: $showingOptions) {
            Button("Edit Name") {
                editedName = viewModel.playlist.name
                showingEditName = true
            }
            
            Button("Add Songs") {
                showingAddSongs = true
            }
            
            Button("Delete Playlist", role: .destructive) {
                showingDeleteConfirmation = true
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Playlist", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deletePlaylist()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this playlist? This action cannot be undone.")
        }
        .alert("Edit Playlist Name", isPresented: $showingEditName) {
            TextField("Playlist Name", text: $editedName)
            Button("Save") {
                viewModel.updatePlaylistName(editedName)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a new name for your playlist")
        }
        .sheet(isPresented: $showingAddSongs) {
            AddSongsView(playlist: viewModel.playlist)
        }
        .overlay {
            if viewModel.isLoading {
                ThemeLoadingView()
            }
        }
    }
}

struct PlaylistHeaderView: View {
    let playlist: Playlist
    let onPlay: () -> Void
    let onShuffle: () -> Void
    
    var body: some View {
        VStack(spacing: ThemeMetrics.Padding.large) {
            // Playlist Cover
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
                                .font(.system(size: ThemeMetrics.IconSize.extraLarge))
                                .foregroundColor(ThemeColor.secondaryText.color)
                        )
                }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: ThemeMetrics.CornerRadius.large))
            .shadow(radius: ThemeShadow.large.radius)
            
            // Playlist Info
            VStack(spacing: ThemeMetrics.Padding.small) {
                Text(playlist.name)
                    .font(ThemeFont.title())
                    .foregroundColor(ThemeColor.text.color)
                
                Text("\(playlist.songs.count) songs")
                    .font(ThemeFont.body())
                    .foregroundColor(ThemeColor.secondaryText.color)
            }
            
            // Action Buttons
            HStack(spacing: ThemeMetrics.Padding.large) {
                Button(action: onPlay) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .font(ThemeFont.headline())
                }
                .themeButton()
                .frame(maxWidth: .infinity)
                
                Button(action: onShuffle) {
                    HStack {
                        Image(systemName: "shuffle")
                        Text("Shuffle")
                    }
                    .font(ThemeFont.headline())
                }
                .themeButton(style: .secondary)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical)
    }
}

struct PlaylistSongRow: View {
    let song: Song
    let index: Int
    let isPlaying: Bool
    let onPlay: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: ThemeMetrics.Padding.medium) {
            Text("\(index)")
                .font(ThemeFont.body())
                .foregroundColor(ThemeColor.secondaryText.color)
                .frame(width: 30)
            
            AsyncImage(url: URL(string: song.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(ThemeColor.secondaryText.color.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: ThemeMetrics.CornerRadius.small))
            
            VStack(alignment: .leading, spacing: ThemeMetrics.Padding.small) {
                Text(song.title)
                    .font(ThemeFont.body())
                    .foregroundColor(isPlaying ? ThemeColor.accent.color : ThemeColor.text.color)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(ThemeFont.caption())
                    .foregroundColor(ThemeColor.secondaryText.color)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isPlaying {
                Image(systemName: "music.note")
                    .font(.system(size: ThemeMetrics.IconSize.medium))
                    .foregroundColor(ThemeColor.accent.color)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, ThemeMetrics.Padding.small)
        .contentShape(Rectangle())
        .onTapGesture(perform: onPlay)
    }
}

struct AddSongsView: View {
    let playlist: Playlist
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchViewModel = SearchViewModel()
    
    var body: some View {
        NavigationView {
            SearchView()
                .navigationTitle("Add Songs")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    NavigationView {
        PlaylistDetailView(playlist: Playlist(
            id: "1",
            name: "My Playlist",
            songs: []
        ))
    }
}
