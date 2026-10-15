import Foundation
import Combine
import AppKit
import SwiftUI

class AppSearchEngine: ObservableObject {
    @Published var searchResults: [CueResult] = []
    @Published var currentQuery: String = ""
    
    private var allCurrentMatches: [CueResult] = []
    private var lastCycleTime: TimeInterval = 0
    
    private var allApps: [AppResult] {
        return AppRegistry.shared.installedApps
    }
    
    /// Apps after applying the user's Exclusion List from Settings
    private var filteredApps: [AppResult] {
        let excluded = CueSettings.exclusionList.map { $0.lowercased() }
        guard !excluded.isEmpty else { return allApps }
        return allApps.filter { !excluded.contains($0.lowercasedName) }
    }
    
    // Store habit statistics: ["query" : ["AppName": launchCount]]
    @AppStorage("AppHabitsData") private var habitDataValue: Data = Data()
    private var habits: [String: [String: Int]] = [:]
    
    init() {
        loadHabits()
    }
    
    // MARK: - Key Event Handling
    
    func handleKeyEvent(_ event: NSEvent) {
        // Handle Escape
        if event.keyCode == 53 {
            DispatchQueue.main.async {
                WindowManager.shared.hideWindow()
            }
            return
        }
        
        // Handle Backspace
        if event.keyCode == 51 {
            if !currentQuery.isEmpty {
                currentQuery.removeLast()
                performSearch()
            }
            return
        }
        
        // Handle Enter/Return
        if event.keyCode == 36 || event.keyCode == 76 {
            if let first = searchResults.first {
                execute(result: first)
            }
            return
        }
        
        // Handle typed characters
        if let chars = event.charactersIgnoringModifiers {
            let lowerChar = chars.lowercased()
            
            // Allow alphanumerics, space, and calculator/file characters
            let allowedChars = CharacterSet.alphanumerics
                .union(CharacterSet(charactersIn: " ._+-*/()"))
            guard lowerChar.unicodeScalars.allSatisfy({ allowedChars.contains($0) }) else {
                return
            }
            
            // Checking for identical single-letter tap (Cycling)
            if currentQuery.count == 1 && currentQuery == lowerChar && allCurrentMatches.count > 1 {
                if event.isARepeat {
                    let now = Date().timeIntervalSince1970
                    if now - lastCycleTime > 0.15 {
                        lastCycleTime = now
                        cycleResults()
                    }
                } else {
                    lastCycleTime = Date().timeIntervalSince1970
                    cycleResults()
                }
            } else {
                currentQuery += lowerChar
                performSearch()
            }
        }
    }
    
    func reset() {
        currentQuery = ""
        performSearch()
    }
    
    // MARK: - Search
    
    private func performSearch() {
        if currentQuery.isEmpty {
            // Show most-used apps based on the "__global__" habit key
            let globalHabits = habits["__global__"] ?? [:]
            
            let sortedApps = filteredApps.sorted { app1, app2 in
                let count1 = globalHabits[app1.name] ?? 0
                let count2 = globalHabits[app2.name] ?? 0
                if count1 == count2 {
                    return app1.name < app2.name
                }
                return count1 > count2
            }
            
            allCurrentMatches = sortedApps.map { .app($0) }
            publishResults()
            return
        }
        
        var results: [CueResult] = []
        let query = currentQuery.lowercased()
        
        // 1. Calculator / Currency Conversion (highest priority)
        if let calcResult = CalculatorEngine.evaluate(query) {
            results.append(.calculatorAnswer(calcResult))
        }
        
        // 2. System Commands
        let matchedCommands = SystemCommandProvider.shared.search(query: query)
        for cmd in matchedCommands {
            results.append(.systemCommand(cmd))
        }

        // 3. System Settings panes (e.g. "Wi-Fi", "Displays", "Appearance")
        let matchedSettings = SystemSettingsProvider.shared.search(query: query)
        for pane in matchedSettings {
            results.append(.systemCommand(pane))
        }

        // 4. App Search
        var scoredApps: [(app: AppResult, matchScore: Int)] = []
        
        for app in filteredApps {
            let name = app.lowercasedName
            var score = 0
            
            if name == query {
                score = 200
            } else if name.hasPrefix(query) {
                score = 100
            } else if name.contains(query) {
                score = 50
            }
            
            // Acronym matching
            if score == 0 {
                if app.acronym.hasPrefix(query) {
                    score = 40
                }
            }
            
            if score > 0 {
                let historyCount = habits[query]?[app.name] ?? 0
                score += (historyCount * 15)
                scoredApps.append((app, score))
            }
        }
        
        scoredApps.sort {
            if $0.matchScore == $1.matchScore {
                return $0.app.name < $1.app.name
            }
            return $0.matchScore > $1.matchScore
        }
        
        for scored in scoredApps {
            results.append(.app(scored.app))
        }
        
        allCurrentMatches = results
        publishResults()
        
        // 5. Async File Search (for queries >= 3 characters)
        if query.count >= 3 {
            let searchQuery = query
            FileSearchProvider.shared.search(query: searchQuery) { [weak self] files in
                guard let self = self else { return }
                // Only merge if the query hasn't changed
                guard self.currentQuery.lowercased() == searchQuery else { return }
                // Append file results after existing results
                let fileResults = files.map { CueResult.file($0) }
                self.allCurrentMatches.append(contentsOf: fileResults)
                self.publishResults()
            }
        }
    }
    
    private func publishResults() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            searchResults = Array(allCurrentMatches.prefix(CueSettings.resultLimit))
        }
    }
    
    private func cycleResults() {
        guard !allCurrentMatches.isEmpty else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            let first = allCurrentMatches.removeFirst()
            allCurrentMatches.append(first)
            searchResults = Array(allCurrentMatches.prefix(CueSettings.resultLimit))
        }
    }
    
    // MARK: - Execute Result
    
    func execute(result: CueResult) {
        switch result {
        case .app(let app):
            NSWorkspace.shared.open(app.url)
            recordHabit(name: app.name, query: currentQuery)
            
        case .file(let file):
            NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
            
        case .systemCommand(let cmd):
            cmd.action()
            recordHabit(name: cmd.name, query: currentQuery)
            
        case .calculatorAnswer(let calc):
            // Copy result to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(calc.answer, forType: .string)
        }
        
        DispatchQueue.main.async {
            WindowManager.shared.hideWindow()
        }
    }
    
    // MARK: - Habits
    
    private func recordHabit(name: String, query: String) {
        if !query.isEmpty {
            if habits[query] == nil { habits[query] = [:] }
            let currentCount = habits[query]?[name] ?? 0
            habits[query]?[name] = currentCount + 1
        }
        
        let globalKey = "__global__"
        if habits[globalKey] == nil { habits[globalKey] = [:] }
        let globalCount = habits[globalKey]?[name] ?? 0
        habits[globalKey]?[name] = globalCount + 1
        
        saveHabits()
    }
    
    private func saveHabits() {
        if let data = try? JSONEncoder().encode(habits) {
            habitDataValue = data
        }
    }
    
    private func loadHabits() {
        if let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: habitDataValue) {
            self.habits = decoded
        }
    }
}
