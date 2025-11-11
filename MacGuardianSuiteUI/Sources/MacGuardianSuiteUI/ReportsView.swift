import SwiftUI
import WebKit
#if os(macOS)
import AppKit
#endif

struct ReportsView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var reports: [ReportFile] = []
    @State private var selectedReport: ReportFile?
    @State private var searchText: String = ""
    
    var body: some View {
        HSplitView {
            // Reports List
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    LogoView(size: 32)
                    Text("Reports")
                        .font(.headline)
                        .foregroundColor(.themeText)
                    Spacer()
                    Button {
                        refreshReports()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .tint(.themePurple)
                }
                .padding()
                
                SearchField(text: $searchText, placeholder: "Search reports...")
                    .padding(.horizontal)
                
                List(selection: $selectedReport) {
                    ForEach(filteredReports) { report in
                        ReportRow(report: report)
                            .tag(report)
                    }
                }
                .listStyle(.sidebar)
                .background(Color.themeDarkGray)
            }
            .frame(minWidth: 250, idealWidth: 300)
            .background(Color.themeDarkGray)
            
            // Report Preview
            if let report = selectedReport {
                ReportPreviewView(report: report)
            } else {
                ContentUnavailableView(
                    "Select a Report",
                    systemImage: "doc.text",
                    description: Text("Choose a report from the list to view it")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.themeBlack)
            }
        }
        .background(Color.themeBlack)
        .onAppear {
            refreshReports()
        }
    }
    
    private var filteredReports: [ReportFile] {
        if searchText.isEmpty {
            return reports
        }
        return reports.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func refreshReports() {
        reports = workspace.loadReports()
        if selectedReport == nil, let firstReport = reports.first {
            selectedReport = firstReport
        }
    }
}

struct ReportRow: View {
    let report: ReportFile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(report.name)
                .font(.subheadline.bold())
                .foregroundColor(.themeText)
                .lineLimit(1)
            
            HStack {
                Text(formatDate(report.date))
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
                Spacer()
                Text(report.formattedSize)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ReportPreviewView: View {
    let report: ReportFile
    @State private var htmlContent: String = ""
    @State private var textContent: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                LogoView(size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.name)
                        .font(.headline)
                        .foregroundColor(.themeText)
                    Text(formatDate(report.date))
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        openInFinder()
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                    .tint(.themePurple)
                    
                    #if os(macOS)
                    Button {
                        shareReport()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .tint(.themePurple)
                    #endif
                }
            }
            .padding()
            .background(Color.themeDarkGray)
            
            Divider()
                .background(Color.themePurpleDark)
            
            // Content
            if report.url.pathExtension == "html" {
                WebView(htmlContent: htmlContent)
                    .onAppear {
                        loadHTML()
                    }
            } else {
                ScrollView {
                    Text(textContent.isEmpty ? "Loading..." : textContent)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.themeText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.themeBlack)
                .onAppear {
                    loadText()
                }
            }
        }
        .background(Color.themeBlack)
    }
    
    private func loadHTML() {
        if let data = try? Data(contentsOf: report.url),
           let content = String(data: data, encoding: .utf8) {
            htmlContent = content
        } else {
            htmlContent = "<html><body><p>Error loading report</p></body></html>"
        }
    }
    
    private func loadText() {
        if let data = try? Data(contentsOf: report.url),
           let content = String(data: data, encoding: .utf8) {
            textContent = content
        } else {
            textContent = "Error loading report"
        }
    }
    
    private func openInFinder() {
        #if os(macOS)
        NSWorkspace.shared.selectFile(report.url.path, inFileViewerRootedAtPath: "")
        #endif
    }
    
    private func shareReport() {
        #if os(macOS)
        let picker = NSSharingServicePicker(items: [report.url])
        if let window = NSApplication.shared.keyWindow,
           let contentView = window.contentView {
            picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        }
        #endif
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct WebView: NSViewRepresentable {
    let htmlContent: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if htmlContent != "" {
            nsView.loadHTMLString(htmlContent, baseURL: nil)
        }
    }
}

struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.themeTextSecondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(.themeText)
        }
        .padding(8)
        .background(Color.themeBlack, in: RoundedRectangle(cornerRadius: 8))
    }
}

