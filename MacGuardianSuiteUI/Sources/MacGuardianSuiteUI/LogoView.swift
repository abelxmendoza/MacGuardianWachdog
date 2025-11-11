import SwiftUI

struct LogoView: View {
    let size: CGFloat
    
    init(size: CGFloat = 120) {
        self.size = size
    }
    
    var body: some View {
        Group {
            if let logoImage = loadLogoImage() {
                Image(nsImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                // Fallback to system icon if logo not found
                VStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: size * 0.6))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.themePurple, .themePurpleLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("MACGUARDIAN")
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundColor(.themePurple)
                    Text("WATCHDOG")
                        .font(.system(size: size * 0.12, weight: .medium))
                        .foregroundColor(.themePurpleDark)
                }
            }
        }
    }
    
    #if os(macOS)
    private func loadLogoImage() -> NSImage? {
        // List of possible logo filenames (in order of preference)
        let logoNames = ["MacGlogo", "MacGuardianLogo"]
        let extensions = ["png", "jpg", "jpeg"]
        
        // Try to load from main bundle (for app bundle)
        for logoName in logoNames {
            for ext in extensions {
                if let imagePath = Bundle.main.path(forResource: logoName, ofType: ext) {
                    return NSImage(contentsOfFile: imagePath)
                }
            }
        }
        
        // Try to load from Resources directory relative to executable
        var possiblePaths: [String] = []
        
        for logoName in logoNames {
            for ext in extensions {
                // Bundle resource paths
                possiblePaths.append("\(Bundle.main.resourcePath ?? "")/\(logoName).\(ext)")
                possiblePaths.append("\(Bundle.main.resourcePath ?? "")/images/\(logoName).\(ext)")
                
                // Development paths
                possiblePaths.append("\(FileManager.default.currentDirectoryPath)/Resources/\(logoName).\(ext)")
                possiblePaths.append("\(FileManager.default.currentDirectoryPath)/Resources/images/\(logoName).\(ext)")
            }
        }
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return NSImage(contentsOfFile: path)
            }
        }
        
        return nil
    }
    #endif
}

