import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @StateObject private var processor = CalendarProcessor()
    @State private var isImporterPresented = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Calendar Fixer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            VStack(alignment: .leading) {
                Text("Courses to keep (comma separated, leave empty to keep all):")
                    .font(.headline)
                TextField("e.g. Math, Physics, History", text: $processor.coursesToKeep)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            Button(action: {
                isImporterPresented = true
            }) {
                Text("Select .ics File")
                    .font(.title2)
                    .padding()
                    .frame(minWidth: 200)
            }
            .disabled(processor.isProcessing)
            .padding()
            
            if processor.isProcessing {
                ProgressView("Processing...")
            }
            
            VStack(alignment: .leading) {
                Text("Logs:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ScrollView {
                    Text(processor.logs)
                        .font(.custom("Menlo", size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(5)
                }
                .frame(height: 150)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            
            if let result = processor.resultParams {
                VStack {
                    Text("Success!")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("Saved to: \(result.path)")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Show in Finder") {
                        NSWorkspace.shared.selectFile(result.path, inFileViewerRootedAtPath: "")
                    }
                    .padding(.top, 5)
                }
                .padding(.bottom)
                .transition(.opacity)
            }
        }
        .frame(minWidth: 500, minHeight: 450)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [UTType.item], // Fallback to item
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    processor.processFile(at: url)
                }
            case .failure(let error):
                processor.logs += "Error selecting file: \(error.localizedDescription)\n"
            }
        }
    }
}
