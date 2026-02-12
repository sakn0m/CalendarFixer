import SwiftUI
import Combine

class CalendarProcessor: ObservableObject {
    @Published var coursesToKeep: String {
        didSet {
            UserDefaults.standard.set(coursesToKeep, forKey: "coursesToKeep")
        }
    }
    
    init() {
        self.coursesToKeep = UserDefaults.standard.string(forKey: "coursesToKeep") ?? ""
    }

    @Published var isProcessing: Bool = false
    @Published var logs: String = ""
    // Use a struct or tuple for result to avoid optional checking mess
    @Published var resultParams: (path: String, total: Int, kept: Int)? = nil

    func processFile(at url: URL) {
        log("Inizio elaborazione file: \(url.lastPathComponent)")
        isProcessing = true
        resultParams = nil
        
        // Capture value on main thread
        let keywords = self.coursesToKeep
        
        // Read file content synchronously to ensure security scope validity if passed
        // For very large files this might block UI briefly, but for ICS it's fine.
        var fileContent = ""
        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            fileContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            log("Errore lettura file: \(error.localizedDescription)")
            isProcessing = false
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Use the already read content
                let (processedContent, total, kept) = self.processICS(fileContent, keywords)
                
                let outputURL = url.deletingPathExtension().appendingPathExtension("_filtered.ics")
                try processedContent.write(to: outputURL, atomically: true, encoding: .utf8)
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.resultParams = (outputURL.path, total, kept)
                    self.log("File salvato in: \(outputURL.lastPathComponent)")
                    self.log("Eventi totali: \(total), mantenuti: \(kept)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.log("Errore: \(error.localizedDescription)")
                }
            }
        }
    }

    private func log(_ message: String) {
        DispatchQueue.main.async {
            self.logs += "\(message)\n"
        }
    }
    
    // Core logic
    private func processICS(_ content: String, _ keywordsString: String) -> (String, Int, Int) {
        // 1. Unfold lines (basic implementation)
        // Note: Real ICS unfolding is more complex, but this handles standard implementations.
        var unfolded = content.replacingOccurrences(of: "\r\n ", with: "")
        unfolded = unfolded.replacingOccurrences(of: "\n ", with: "") 
        
        let lines = unfolded.components(separatedBy: CharacterSet.newlines)
        
        var outputLines = [String]()
        var currentEventLines = [String]()
        var inEvent = false
        var totalEvents = 0
        var keptEvents = 0
        
        let keywords = keywordsString.lowercased()
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            
        let keepAll = keywords.isEmpty
        
        for line in lines {
            if line.hasPrefix("BEGIN:VEVENT") {
                inEvent = true
                currentEventLines = [line]
                continue
            }
            
            if inEvent {
                currentEventLines.append(line)
                if line.hasPrefix("END:VEVENT") {
                    totalEvents += 1
                    
                    // Process event
                    if let processedEvent = processEvent(currentEventLines, keywords: keywords, keepAll: keepAll) {
                        outputLines.append(contentsOf: processedEvent)
                        keptEvents += 1
                    }
                    inEvent = false
                    currentEventLines = []
                }
                continue
            }
            
            // Non-event lines (headers, footers)
            outputLines.append(line)
        }
        
        // Join with CRLF which is standard for ICS
        return (outputLines.joined(separator: "\r\n"), totalEvents, keptEvents)
    }
    
    private func processEvent(_ eventLines: [String], keywords: [String], keepAll: Bool) -> [String]? {
        // Check filtering first
        var keep = keepAll
        if !keepAll {
            var summaryFound = false
            for line in eventLines {
                if line.hasPrefix("SUMMARY") {
                    let parts = line.split(separator: ":", maxSplits: 1)
                    if parts.count > 1 {
                        let summary = String(parts[1]).lowercased()
                        if keywords.contains(where: { summary.contains($0) }) {
                            keep = true
                            summaryFound = true
                            break
                        }
                    }
                }
            }
            // If no summary found, default to keep? No, default to drop if we are filtering.
        }
        
        if !keep { return nil }
        
        // Fix Timezone
        var newLines = [String]()
        let targetTZ = "Europe/Brussels"
        
        for line in eventLines {
            var newLine = line
            var isDateTimeProperty = false
            
            // Check for DTSTART or DTEND
            if line.hasPrefix("DTSTART") { isDateTimeProperty = true }
            else if line.hasPrefix("DTEND") { isDateTimeProperty = true }
            
            if isDateTimeProperty {
                // Parse key and value
                // Format: KEY;PARAM=VAL:VALUE
                let parts = line.split(separator: ":", maxSplits: 1)
                
                if parts.count == 2 {
                    let keyPart = String(parts[0])
                    var valuePart = String(parts[1])
                    
                    // Only modify if it looks like a DateTime (has 'T')
                    // If it's a DATE (just YYYYMMDD), usually no timezone is needed/allowed in the same way.
                    if valuePart.contains("T") {
                        // Remove 'Z' if present
                        if valuePart.hasSuffix("Z") {
                            valuePart.removeLast()
                        }
                        
                        // Extract base property name (DTSTART, DTEND) ignoring existing params
                        let baseProp = keyPart.contains(";") ? String(keyPart.split(separator: ";")[0]) : keyPart
                        
                        // We replace all params with TZID=... 
                        // Note: This drops other params like VALUE=DATE-TIME, but that's default.
                        // It drops RSVP, CN? No, those aren't on DTSTART usually.
                        newLine = "\(baseProp);TZID=\(targetTZ):\(valuePart)"
                    }
                }
            }
            newLines.append(newLine)
        }
        
        return newLines
    }
}
