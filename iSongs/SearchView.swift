import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var playbackManager = PlaybackManager.shared
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: ThemeGradient.primary),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                    ThemeEmptyStateView(
                        icon: "magnifyingglass",
                        message: "Search for your favorite songs, artists, or albums"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: ThemeMetrics.Padding.small) {
                            if !viewModel.recentSearches.isEmpty && viewModel.searchText.isEmpty {
                                RecentSearchesSection(
                                    searches: viewModel.recentSearches,
                                    onTapSearch: { search in
                                        viewModel.searchText = search
                                        Task {
                                            await viewModel.performSearch()
                                        }
                                    },
                                    onClearSearches: {
                                        viewModel.clearRecentSearches()
                                    }
                                )
                            }
                            
                            ForEach(viewModel.searchResults) { song in
                                SearchResultRow(
                                    song: song,
                                    isPlaying: playbackManager.currentSong?.id == song.id
                                )
                                .onTapGesture {
                                    Task {
                                        await playbackManager.play(song)
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        viewModel.addToPlaylist(song)
                                    } label: {
                                        Label("Add to Playlist", systemImage: "plus.circle")
                                    }
                                    
                                    Button {
                                        viewModel.addToQueue(song)
                                    } label: {
                                        Label("Add to Queue", systemImage: "text.badge.plus")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                if viewModel.isSearching {
                    ThemeLoadingView()
                }
            }
        }
        .navigationTitle("Search")
        .searchable(
            text: $viewModel.searchText,
            prompt: "Songs, artists, or albums"
        )
        .onChange(of: viewModel.searchText) { _ in
            Task {
                await viewModel.performSearch()
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

struct RecentSearchesSection: View {
    let searches: [String]
    let onTapSearch: (String) -> Void
    let onClearSearches: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: ThemeMetrics.Padding.medium) {
            HStack {
                Text("Recent Searches")
                    .font(ThemeFont.headline())
                    .foregroundColor(ThemeColor.text.color)
                
                Spacer()
                
                Button(action: onClearSearches) {
                    Text("Clear")
                        .font(ThemeFont.body())
                        .foregroundColor(ThemeColor.accent.color)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ThemeMetrics.Padding.small) {
                    ForEach(searches, id: \.self) { search in
                        Button(action: {
                            onTapSearch(search)
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: ThemeMetrics.IconSize.small))
                                Text(search)
                                    .font(ThemeFont.body())
                            }
                            .padding(.horizontal, ThemeMetrics.Padding.medium)
                            .padding(.vertical, ThemeMetrics.Padding.small)
                            .background(ThemeColor.secondaryText.color.opacity(0.2))
                            .clipShape(Capsule())
                        }
                        .foregroundColor(ThemeColor.text.color)
                    }
                }
            }
        }
        .padding(.vertical, ThemeMetrics.Padding.medium)
    }
}

struct SearchResultRow: View {
    let song: Song
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: ThemeMetrics.Padding.medium) {
            AsyncImage(url: URL(string: song.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(ThemeColor.secondaryText.color.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(ThemeColor.secondaryText.color)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: ThemeMetrics.CornerRadius.small))
            .shadow(radius: ThemeShadow.small.radius)
            
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
            } else {
                Button(action: {}) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: ThemeMetrics.IconSize.large))
                        .foregroundColor(ThemeColor.text.color)
                }
            }
        }
        .padding(.vertical, ThemeMetrics.Padding.small)
        .contentShape(Rectangle())
    }
}

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [Song] = []
    @Published var recentSearches: [String] = []
    @Published var isSearching = false
    @Published var showingError = false
    @Published var errorMessage: String?
    
    private let youtubeService = YouTubeService.shared
    private var searchTask: Task<Void, Never>?
    
    func performSearch() async {
        searchTask?.cancel()
        
        guard !searchText.isEmpty else {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            return
        }
        
        searchTask = Task {
            await MainActor.run {
                isSearching = true
            }
            
            do {
                let results = try await youtubeService.searchVideos(query: searchText)
                
                if !Task.isCancelled {
                    await MainActor.run {
                        searchResults = results
                        isSearching = false
                        addToRecentSearches(searchText)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showingError = true
                        isSearching = false
                    }
                }
            }
        }
    }
    
    private func addToRecentSearches(_ search: String) {
        if !recentSearches.contains(search) {
            recentSearches.insert(search, at: 0)
            if recentSearches.count > 5 {
                recentSearches.removeLast()
            }
        }
    }
    
    func clearRecentSearches() {
        recentSearches.removeAll()
    }
    
    func addToPlaylist(_ song: Song) {
        // Implement add to playlist functionality
    }
    
    func addToQueue(_ song: Song) {
        // Implement add to queue functionality
    }
}

#Preview {
    NavigationView {
        SearchView()
    }
}
