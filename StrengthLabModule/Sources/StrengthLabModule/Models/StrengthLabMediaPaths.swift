import Foundation
import SwiftData

// Saved file URLs include an iOS app-container UUID that can change after an
// Xcode reinstall/update. Files can still exist under the *current* sandbox.
// Resolve them by their known StrengthLab media subfolder and original filename.
// Do not copy/delete files and do not erase a reference if its file is missing.
enum StrengthLabMediaPaths {
    private static let knownFolders: Set<String> = [
        "ImportedVideos", "ExerciseDemos", "EditedGIFs"
    ]

    static func available(_ original: URL?) -> URL? {
        guard let original else { return nil }

        // Some previously saved URLs accidentally contained a second file://.
        // Recover the innermost valid file URL without changing remote links.
        let candidate: URL
        if original.isFileURL {
            candidate = original
        } else if let range = original.absoluteString.range(
            of: "file:///", options: .backwards
        ), let nested = URL(string: String(original.absoluteString[range.lowerBound...])) {
            candidate = nested
        } else {
            return original // YouTube and other ordinary remote URLs stay intact.
        }

        guard candidate.isFileURL else { return nil }
        let fm = FileManager.default
        if fm.fileExists(atPath: candidate.path) { return candidate }

        // Only rebase app-owned media. No filename-only search across folders.
        let pieces = candidate.path.components(separatedBy: "/")
        guard let i = pieces.lastIndex(of: "StrengthLab"),
              i + 2 < pieces.count,
              knownFolders.contains(pieces[i + 1]),
              let appSupport = fm.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
              ).first else { return nil }

        var current = appSupport.appendingPathComponent(
            "StrengthLab", isDirectory: true
        )
        for piece in pieces[(i + 1)...] {
            guard !piece.isEmpty && piece != "." && piece != ".." else { return nil }
            current.appendPathComponent(piece)
        }
        return fm.fileExists(atPath: current.path) ? current : nil
    }

    static func relinkStoredMedia(in context: ModelContext) {
        let exercises: [SetDeckExercise]
        do {
            exercises = try context.fetch(FetchDescriptor<SetDeckExercise>())
        } catch {
            print("[StrengthLab Media] Cannot inspect media records: \(error)")
            return
        }

        var fixed = 0
        var unavailable = 0
        func check(_ old: URL?, assign: (URL) -> Void) {
            guard let old else { return }
            if let good = available(old) {
                if good != old { assign(good); fixed += 1 }
            } else if old.isFileURL || old.absoluteString.contains("file:///") {
                unavailable += 1
                // Retain the original URL: missing media could still be restored
                // from a device backup or re-imported. Never silently set nil.
            }
        }

        for exercise in exercises {
            check(exercise.videoURL) { exercise.videoURL = $0 }
            check(exercise.importedVideoURL) { exercise.importedVideoURL = $0 }
            check(exercise.gifURL) { exercise.gifURL = $0 }
            check(exercise.gifSourceURL) { exercise.gifSourceURL = $0 }
        }
        if fixed > 0 {
            do { try context.save() }
            catch { print("[StrengthLab Media] Re-link save failed: \(error)") }
        }
        print("[StrengthLab Media] Re-linked \(fixed) reference(s); \(unavailable) local reference(s) still unavailable. Nothing deleted.")
    }
}
