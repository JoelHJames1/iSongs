import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class HomeViewModel: ObservableObject {
    @Published var recentlyPlayed: [Song] = []
    @Published var popularSongs: [Song] = []
    @Published var userPlaylists: [Playlist] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private let youtubeService = YouTubeService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Listen for playback changes to update recently played
        NotificationCenter.default.publisher(for: NSNotification.Name("SongPlayed"))
            .compactMap { $0.object as? Song }
            .sink { [weak self] song in
                self?.addToRecentlyPlayed(song)
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        error = nil
        
        // Load data concurrently
        Task {
            async let recentlyPlayedTask = fetchRecentlyPlayed(userId)
            async let popularSongsTask = fetchPopularSongs()
            async let playlistsTask = fetchUserPlaylists(userId)
            
            do {
                // Await all concurrent tasks
                let (recent, popular, playlists) = await (
                    try recentlyPlayedTask,
                    try popularSongsTask,
                    try playlistsTask
                )
                
                // Update UI on main thread
                await MainActor.run {
                    self.recentlyPlayed = recent
                    self.popularSongs = popular
                    self.userPlaylists = playlists
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchRecentlyPlayed(_ userId: String) async throws -> [Song] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("recentlyPlayed")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> Song? in
            try? doc.data(as: Song.self)
        }
    }
    
    private func fetchPopularSongs() async throws -> [Song] {
        // First try to get cached popular songs
        if let cached = try? await fetchCachedPopularSongs() {
            return cached
        }
        
        // If no cache or expired, fetch from YouTube
        let songs = try await youtubeService.searchVideos(query: "popular music trending")
        
        // Cache the results
        await cachePopularSongs(songs)
        
        return songs
    }
    
    private func fetchCachedPopularSongs() async throws -> [Song]? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        
        let snapshot = try await db.collection("cache")
            .document("popularSongs")
            .getDocument()
        
        guard let data = snapshot.data(),
              let timestamp = data["timestamp"] as? Timestamp,
              let cachedSongs = try? JSONDecoder().decode([Song].self, from: data["songs"] as? Data ?? Data()) else {
            return nil
        }
        
        // Check if cache is still valid (less than 1 hour old)
        let cacheAge = Date().timeIntervalSince(timestamp.dateValue())
        if cacheAge > 3600 { // 1 hour in seconds
            return nil
        }
        
        return cachedSongs
    }
    
    private func cachePopularSongs(_ songs: [Song]) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let songsData = try JSONEncoder().encode(songs)
            try await db.collection("cache")
                .document("popularSongs")
                .setData([
                    "songs": songsData,
                    "timestamp": Timestamp(date: Date())
                ])
        } catch {
            print("Error caching popular songs: \(error)")
        }
    }
    
    private func fetchUserPlaylists(_ userId: String) async throws -> [Playlist] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("playlists")
            .limit(to: 5)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> Playlist? in
            try? doc.data(as: Playlist.self)
        }
    }
    
    private func addToRecentlyPlayed(_ song: Song) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                // Add to Firestore with timestamp
                try await db.collection("users")
                    .document(userId)
                    .collection("recentlyPlayed")
                    .document(song.id)
                    .setData([
                        "song": try JSONEncoder().encode(song),
                        "timestamp": Timestamp(date: Date())
                    ])
                
                // Update local state
                await MainActor.run {
                    if !self.recentlyPlayed.contains(where: { $0.id == song.id }) {
                        self.recentlyPlayed.insert(song, at: 0)
                        if self.recentlyPlayed.count > 10 {
                            self.recentlyPlayed.removeLast()
                        }
                    }
                }
            } catch {
                print("Error adding to recently played: \(error)")
            }
        }
    }
    
    func refreshData() {
        loadData()
    }
    
    func playSong(_ song: Song) {
        Task {
            await PlaybackManager.shared.play(song)
        }
    }
    
    func clearRecentlyPlayed() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                // Delete all documents in recentlyPlayed collection
                let snapshot = try await db.collection("users")
                    .document(userId)
                    .collection("recentlyPlayed")
                    .getDocuments()
                
                for document in snapshot.documents {
                    try await document.reference.delete()
                }
                
                // Update local state
                await MainActor.run {
                    self.recentlyPlayed.removeAll()
                }
            } catch {
                print("Error clearing recently played: \(error)")
            }
        }
    }
}
