import Foundation
import AppKit
import SwiftUI

class FileSearchProvider {

    static let shared = FileSearchProvider()

    private var query: NSMetadataQuery?
    private var completion: (([FileResult]) -> Void)?
    private var searchLimit: Int = 3

    /// Only search files in Desktop, Documents, and Downloads
    private var allowedDirectories: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(home)/Desktop",
            "\(home)/Documents",
            "\(home)/Downloads"
        ]
    }

    private init() {}

    func search(query searchText: String, limit: Int = 3, completion: @escaping ([FileResult]) -> Void) {
        self.searchLimit = limit
        self.completion = completion

        self.query?.stop()
        NotificationCenter.default.removeObserver(self)

        let sanitized = searchText.trimmingCharacters(in: .whitespaces)
        guard !sanitized.isEmpty else {
            completion([])
            return
        }

        let metadataQuery = NSMetadataQuery()

        // Restrict search scope to Desktop, Documents, Downloads only
        metadataQuery.searchScopes = allowedDirectories

        metadataQuery.predicate = NSPredicate(
            format: "kMDItemDisplayName CONTAINS[cd] %@ AND kMDItemContentType != 'com.apple.application-bundle'",
            sanitized
        )

        metadataQuery.sortDescriptors = [
            NSSortDescriptor(key: "kMDItemLastUsedDate", ascending: false)
        ]

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryDidFinishGathering(_:)),
            name: .NSMetadataQueryDidFinishGathering,
            object: metadataQuery
        )

        self.query = metadataQuery
        metadataQuery.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.query === metadataQuery, metadataQuery.isGathering else { return }
            metadataQuery.stop()
            self.completion?([])
            self.completion = nil
        }
    }

    @objc private func queryDidFinishGathering(_ notification: Notification) {
        guard let metadataQuery = notification.object as? NSMetadataQuery else { return }
        metadataQuery.stop()

        var results: [FileResult] = []
        let workspace = NSWorkspace.shared
        let count = min(metadataQuery.resultCount, searchLimit + 5)

        for i in 0..<count {
            guard results.count < searchLimit else { break }

            guard let item = metadataQuery.result(at: i) as? NSMetadataItem,
                  let path = item.value(forAttribute: kMDItemPath as String) as? String else {
                continue
            }

            let url = URL(fileURLWithPath: path)
            let filename = url.lastPathComponent

            guard !filename.hasPrefix(".") else { continue }

            let icon = workspace.icon(forFile: path)
            icon.size = NSSize(width: 128, height: 128)
            let averageColor = icon.getAverageColor()

            results.append(FileResult(
                path: path,
                name: filename,
                icon: icon,
                averageColor: averageColor
            ))
        }

        DispatchQueue.main.async { [weak self] in
            self?.completion?(results)
            self?.completion = nil
        }
    }
}
