// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "Aura",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Aura", targets: ["Aura"])],
    targets: [.executableTarget(name: "Aura", path: "Sources/Aura")]
)
