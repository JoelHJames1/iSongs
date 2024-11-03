import Foundation

struct Playlist: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let imageURL: String?
    var songs: [Song]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
}
