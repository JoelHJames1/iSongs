import Foundation

enum YouTubeError: Error {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case decodingError
    case noResults
}

class YouTubeService {
    static let shared = YouTubeService()
    private let apiKey = "YOUR_API_KEY"
    private let baseURL = "https://www.googleapis.com/youtube/v3"
    
    private init() {}
    
    func searchVideos(query: String) async throws -> [Song] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search?part=snippet&maxResults=20&q=\(encodedQuery)%20music&type=video&videoCategoryId=10&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw YouTubeError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(YouTubeErrorResponse.self, from: data) {
                throw YouTubeError.apiError(errorResponse.error.message)
            }
            throw YouTubeError.apiError("API request failed with status code \(httpResponse.statusCode)")
        }
        
        do {
            let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            
            guard !searchResponse.items.isEmpty else {
                throw YouTubeError.noResults
            }
            
            return try await getVideoDetails(for: searchResponse.items)
        } catch {
            throw YouTubeError.decodingError
        }
    }
    
    private func getVideoDetails(for searchItems: [YouTubeSearchItem]) async throws -> [Song] {
        let videoIds = searchItems.map { $0.id }.joined(separator: ",")
        
        let urlString = "\(baseURL)/videos?part=contentDetails,snippet&id=\(videoIds)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw YouTubeError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw YouTubeError.invalidResponse
        }
        
        let videoResponse = try JSONDecoder().decode(YouTubeVideoResponse.self, from: data)
        
        return videoResponse.items.map { item in
            Song(
                id: item.id,
                title: item.snippet.title,
                artist: item.snippet.channelTitle,
                thumbnailURL: item.snippet.thumbnails.maxres?.url ?? item.snippet.thumbnails.high.url,
                videoID: item.id
            )
        }
    }
}

// MARK: - Response Models
struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Codable, Identifiable {
    var id: String {  // Computed property to satisfy Identifiable conformance
        return videoID.videoId
    }
    
    let videoID: VideoID // Changed property name to avoid conflict with computed id
    let kind: String
    let snippet: VideoSnippet
}

struct VideoSnippet: Codable {
    let title: String
    let channelTitle: String
    let thumbnails: Thumbnails
}

struct VideoID: Codable {
    let videoId: String
}

struct Thumbnails: Codable {
    let high: ThumbnailInfo
    let maxres: ThumbnailInfo?
}

struct ThumbnailInfo: Codable {
    let url: String
}

struct YouTubeVideoResponse: Codable {
    let items: [YouTubeVideo]
}

struct YouTubeVideo: Codable, Identifiable {
    let id: String
    let snippet: VideoSnippet
    let contentDetails: ContentDetails
}

struct ContentDetails: Codable {
    let duration: String
}

struct YouTubeErrorResponse: Codable {
    let error: APIError
}

struct APIError: Codable {
    let message: String
}

// MARK: - Models
struct Song: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let thumbnailURL: String
    let videoID: String
}

struct Playlist: Identifiable, Codable {
    let id: String
    let name: String
    let songs: [Song]
}
