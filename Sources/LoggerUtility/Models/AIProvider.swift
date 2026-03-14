import Foundation

enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case chatgpt = "ChatGPT"
    case claude = "Claude"
    case gemini = "Gemini"
    case perplexity = "Perplexity"
    case copilot = "Microsoft Copilot"

    var id: String { rawValue }

    /// Whether this provider supports passing a query via URL parameter
    var supportsURLQuery: Bool {
        switch self {
        case .perplexity: return true
        default: return false
        }
    }

    /// Base URL for providers that don't support URL queries
    var baseURL: URL {
        switch self {
        case .chatgpt: return URL(string: "https://chatgpt.com")!
        case .claude: return URL(string: "https://claude.ai/new")!
        case .gemini: return URL(string: "https://gemini.google.com")!
        case .perplexity: return URL(string: "https://www.perplexity.ai")!
        case .copilot: return URL(string: "https://copilot.microsoft.com")!
        }
    }

    /// Build the URL for this provider, optionally embedding the prompt as a query parameter
    func url(withPrompt prompt: String? = nil) -> URL {
        guard let prompt = prompt, supportsURLQuery,
              let encoded = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let queryURL = URL(string: "https://www.perplexity.ai/search?q=\(encoded)") else {
            return baseURL
        }
        return queryURL
    }
}
