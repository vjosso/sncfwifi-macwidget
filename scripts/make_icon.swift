import AppKit

// Génère un PNG 1024×1024 pour l'icône de l'app : squircle carmillon (#7D206F)
// avec un pictogramme de tram blanc centré. Sortie : chemin passé en argument.

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// Fond transparent (le masque squircle est dessiné ci-dessous).
NSColor.clear.set()
NSRect(x: 0, y: 0, width: size, height: size).fill()

// Squircle légèrement encastré (comme les icônes macOS Big Sur+).
let inset: CGFloat = size * 0.085
let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let radius = rect.width * 0.2237
let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

// Dégradé carmillon (haut plus clair, bas plus foncé) pour un rendu moins plat.
let carmillon = NSColor(red: 125 / 255.0, green: 32 / 255.0, blue: 111 / 255.0, alpha: 1)
let carmillonTop = NSColor(red: 150 / 255.0, green: 44 / 255.0, blue: 133 / 255.0, alpha: 1)
let carmillonBottom = NSColor(red: 92 / 255.0, green: 20 / 255.0, blue: 80 / 255.0, alpha: 1)
if let gradient = NSGradient(colors: [carmillonTop, carmillon, carmillonBottom]) {
    gradient.draw(in: squircle, angle: -90)
} else {
    carmillon.set()
    squircle.fill()
}

// Pictogramme "tram.fill" en blanc, centré.
let config = NSImage.SymbolConfiguration(pointSize: rect.width * 0.5, weight: .semibold)
if let base = NSImage(systemSymbolName: "tram.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {

    // Teinte le symbole en blanc.
    let symSize = base.size
    let tinted = NSImage(size: symSize)
    tinted.lockFocus()
    base.draw(at: .zero, from: NSRect(origin: .zero, size: symSize), operation: .sourceOver, fraction: 1)
    NSColor.white.set()
    NSRect(origin: .zero, size: symSize).fill(using: .sourceAtop)
    tinted.unlockFocus()

    let symRect = NSRect(
        x: rect.midX - symSize.width / 2,
        y: rect.midY - symSize.height / 2,
        width: symSize.width,
        height: symSize.height
    )
    tinted.draw(in: symRect)
}

image.unlockFocus()

// Export PNG.
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("Échec de la génération PNG\n".data(using: .utf8)!)
    exit(1)
}
do {
    try png.write(to: URL(fileURLWithPath: outPath))
    print("Icône écrite : \(outPath)")
} catch {
    FileHandle.standardError.write("Échec d'écriture : \(error)\n".data(using: .utf8)!)
    exit(1)
}
