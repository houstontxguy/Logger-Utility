import Foundation

enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case chatgpt = "ChatGPT"
    case claude = "Claude"
    case gemini = "Gemini"
    case perplexity = "Perplexity"
    case copilot = "Microsoft Copilot"

    var id: String { rawValue }

    var url: URL {
        switch self {
        case .chatgpt: return URL(string: "https://chatgpt.com")!
        case .claude: return URL(string: "https://claude.ai/new")!
        case .gemini: return URL(string: "https://gemini.google.com")!
        case .perplexity: return URL(string: "https://www.perplexity.ai")!
        case .copilot: return URL(string: "https://copilot.microsoft.com")!
        }
    }

    var instructions: String {
        switch self {
        case .chatgpt: return "Paste into the message box with Cmd+V"
        case .claude: return "Paste into the message box with Cmd+V"
        case .gemini: return "Paste into the message box with Cmd+V"
        case .perplexity: return "Paste into the search box with Cmd+V"
        case .copilot: return "Paste into the message box with Cmd+V"
        }
    }
}
