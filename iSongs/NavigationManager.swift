import SwiftUI
import Combine

enum NavigationDestination: Hashable, Equatable {
    case playlist(Playlist)
    case search
    case profile
    case settings
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .playlist(let playlist):
            hasher.combine("playlist")
            hasher.combine(playlist.id)
        case .search:
            hasher.combine("search")
        case .profile:
            hasher.combine("profile")
        case .settings:
            hasher.combine("settings")
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.playlist(let lhsPlaylist), .playlist(let rhsPlaylist)):
            return lhsPlaylist.id == rhsPlaylist.id
        case (.search, .search):
            return true
        case (.profile, .profile):
            return true
        case (.settings, .settings):
            return true
        default:
            return false
        }
    }
}

class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: Int = 0
    @Published var presentingMiniPlayer = false
    @Published var isPlayerExpanded = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen for playback changes to show/hide mini player
        PlaybackManager.shared.$currentSong
            .receive(on: DispatchQueue.main)
            .sink { [weak self] song in
                withAnimation {
                    self?.presentingMiniPlayer = song != nil
                }
            }
            .store(in: &cancellables)
    }
    
    func navigateToPlaylist(_ playlist: Playlist) {
        navigationPath.append(NavigationDestination.playlist(playlist))
    }
    
    func navigateToSearch() {
        selectedTab = 1 // Search tab index
    }
    
    func navigateToLibrary() {
        selectedTab = 2 // Library tab index
    }
    
    func navigateToProfile() {
        selectedTab = 3 // Profile tab index
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
}

struct NavigationContainer<Content: View>: View {
    @StateObject private var navigationManager = NavigationManager.shared
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            content
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .playlist(let playlist):
                        PlaylistDetailView(playlist: playlist)
                    case .search:
                        SearchView()
                    case .profile:
                        ProfileView()
                    case .settings:
                        Text("Settings") // Placeholder for settings view
                    }
                }
        }
    }
}

// Custom back button modifier
struct CustomBackButton: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(color)
                    }
                }
            }
    }
}

// Navigation link styles
struct PrimaryNavigationLinkStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
    }
}

struct SecondaryNavigationLinkStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
    }
}

// Extension for easy navigation
extension View {
    func withCustomBackButton(color: Color = .white) -> some View {
        modifier(CustomBackButton(color: color))
    }
    
    func primaryNavigationLinkStyle() -> some View {
        modifier(PrimaryNavigationLinkStyle())
    }
    
    func secondaryNavigationLinkStyle() -> some View {
        modifier(SecondaryNavigationLinkStyle())
    }
}
