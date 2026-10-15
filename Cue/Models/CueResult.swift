import Foundation
import AppKit
import SwiftUI

// MARK: - File Result
struct FileResult: Equatable {
    let path: String
    let name: String
    let icon: NSImage
    let averageColor: Color
    
    static func == (lhs: FileResult, rhs: FileResult) -> Bool {
        lhs.path == rhs.path
    }
}

// MARK: - System Command
struct SystemCommand: Equatable {
    let identifier: String
    let name: String
    let icon: NSImage
    let averageColor: Color
    let action: () -> Void
    
    static func == (lhs: SystemCommand, rhs: SystemCommand) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

// MARK: - Calculator Result
struct CalculatorResult: Equatable {
    let expression: String
    let answer: String
    let icon: NSImage
    let averageColor: Color
}

// MARK: - Unified Cue Result
enum CueResult: Identifiable, Equatable {
    case app(AppResult)
    case file(FileResult)
    case systemCommand(SystemCommand)
    case calculatorAnswer(CalculatorResult)
    
    var id: String {
        switch self {
        case .app(let app): return "app:\(app.url.absoluteString)"
        case .file(let file): return "file:\(file.path)"
        case .systemCommand(let cmd): return "cmd:\(cmd.identifier)"
        case .calculatorAnswer(let calc): return "calc:\(calc.expression)"
        }
    }
    
    var name: String {
        switch self {
        case .app(let app): return app.name
        case .file(let file): return file.name
        case .systemCommand(let cmd): return cmd.name
        case .calculatorAnswer(let calc): return "= \(calc.answer)"
        }
    }
    
    var icon: NSImage {
        switch self {
        case .app(let app): return app.icon
        case .file(let file): return file.icon
        case .systemCommand(let cmd): return cmd.icon
        case .calculatorAnswer(let calc): return calc.icon
        }
    }
    
    var averageColor: Color {
        switch self {
        case .app(let app): return app.averageColor
        case .file(let file): return file.averageColor
        case .systemCommand(let cmd): return cmd.averageColor
        case .calculatorAnswer(let calc): return calc.averageColor
        }
    }
    
    var lowercasedName: String {
        switch self {
        case .app(let app): return app.lowercasedName
        case .file(let file): return file.name.lowercased()
        case .systemCommand(let cmd): return cmd.name.lowercased()
        case .calculatorAnswer(_): return ""
        }
    }
    
    var acronym: String {
        switch self {
        case .app(let app): return app.acronym
        case .file(_): return ""
        case .systemCommand(let cmd):
            return cmd.name.split(separator: " ").compactMap { $0.first?.lowercased() }.joined()
        case .calculatorAnswer(_): return ""
        }
    }
}
