import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    let contentSize = NSSize(width: 400, height: 700)
    self.setContentSize(contentSize)
    self.minSize = contentSize
    self.maxSize = contentSize

    // Position bottom-right of the primary screen with a 20pt margin.
    if let screen = NSScreen.main {
      let visible = screen.visibleFrame
      let x = visible.maxX - contentSize.width - 20
      let y = visible.minY + 20
      self.setFrameOrigin(NSPoint(x: x, y: y))
    } else {
      self.center()
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
