import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var playbackManager = PlaybackManager.shared
    @State private var isAuthenticated = false
    
    private let gradientColors = [
        Color(red: 0.1, green: 0.1, blue: 0.2),
        Color(red: 0.2, green: 0.1, blue: 0.3),
        Color(red: 0.3, green: 0.1, blue: 0.4)
    ]
    
    var body: some View {
        NavigationContainer {
            ZStack(alignment: .bottom) {
                if isAuthenticated {
                    TabView(selection: $navigationManager.selectedTab) {
                        HomeView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                            .tag(0)
                        
                        SearchView()
                            .tabItem {
                                Image(systemName: "magnifyingglass")
                                Text("Search")
                            }
                            .tag(1)
                        
                        LibraryView()
                            .tabItem {
                                Image(systemName: "music.note.list")
                                Text("Library")
                            }
                            .tag(2)
                        
                        ProfileView()
                            .tabItem {
                                Image(systemName: "person.fill")
                                Text("Profile")
                            }
                            .tag(3)
                    }
                    .accentColor(.white)
                    
                    // Mini Player
                    if navigationManager.presentingMiniPlayer {
                        MiniPlayerView(
                            song: $playbackManager.currentSong,
                            isPlaying: $playbackManager.isPlaying,
                            isExpanded: $navigationManager.isPlayerExpanded
                        )
                        .transition(.move(edge: .bottom))
                    }
                } else {
                    AuthenticationView(isAuthenticated: $isAuthenticated)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Check authentication state
            if Auth.auth().currentUser != nil {
                isAuthenticated = true
            }
        }
    }
}

struct HomeView: View {
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var playbackManager = PlaybackManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recently Played Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recently Played")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 15) {
                            ForEach(0..<5) { _ in
                                RecentlyPlayedCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Popular Songs Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Popular Songs")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 15) {
                            ForEach(0..<5) { _ in
                                PopularSongCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Your Playlists Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Your Playlists")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("See All") {
                            navigationManager.navigateToLibrary()
                        }
                        .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 15) {
                            ForEach(0..<5) { _ in
                                PlaylistCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct RecentlyPlayedCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            
            Text("Song Title")
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("Artist")
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(width: 150)
    }
}

struct PopularSongCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            
            Text("Popular Song")
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("Popular Artist")
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(width: 150)
    }
}

struct PlaylistCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            
            Text("Playlist Name")
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 150)
    }
}

#Preview {
    ContentView()
}
