import Foundation

// Keep the old entry point, but derive the mark from the same master as every icon.
// Set KAMUS_PYTHON to a Python executable with Pillow installed when necessary.
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = [ProcessInfo.processInfo.environment["KAMUS_PYTHON"] ?? "python3",
                     root.appendingPathComponent("scripts/make_icon.py").path, "--action-only"]
try process.run()
process.waitUntilExit()
exit(process.terminationStatus)
