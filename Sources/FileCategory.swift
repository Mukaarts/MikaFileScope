// FileCategory.swift
// MikaFileScope

import Foundation

enum FileCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case images = "Images"
    case documents = "Documents"
    case videos = "Videos"
    case audio = "Audio"
    case code = "Code"
    case archives = "Archives"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: "square.grid.2x2"
        case .images: "photo"
        case .documents: "doc.text"
        case .videos: "film"
        case .audio: "music.note"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .archives: "archivebox"
        case .other: "questionmark.folder"
        }
    }

    var extensions: Set<String>? {
        switch self {
        case .all: nil
        case .images: ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "webp", "svg", "ico", "heic", "heif", "raw", "cr2", "nef", "psd", "ai"]
        case .documents: ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "odt", "ods", "odp", "pages", "numbers", "keynote", "csv", "md", "epub"]
        case .videos: ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v", "mpg", "mpeg", "3gp", "ts"]
        case .audio: ["mp3", "wav", "aac", "flac", "ogg", "wma", "m4a", "aiff", "aif", "opus", "mid", "midi"]
        case .code: ["swift", "py", "js", "ts", "tsx", "jsx", "html", "css", "scss", "json", "xml", "yaml", "yml", "sh", "bash", "zsh", "rb", "go", "rs", "c", "cpp", "h", "hpp", "java", "kt", "m", "mm", "sql", "r", "php", "dart", "lua", "toml"]
        case .archives: ["zip", "tar", "gz", "bz2", "xz", "7z", "rar", "dmg", "iso", "pkg", "deb", "rpm", "jar", "war"]
        case .other: nil
        }
    }

    func matches(ext: String) -> Bool {
        switch self {
        case .all:
            return true
        case .other:
            let allKnown = FileCategory.allCases
                .compactMap(\.extensions)
                .reduce(into: Set<String>()) { $0.formUnion($1) }
            return !allKnown.contains(ext)
        default:
            return extensions?.contains(ext) ?? false
        }
    }
}
