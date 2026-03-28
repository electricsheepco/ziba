import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    let contentSize = NSSize(width: 540, height: 680)
    self.setContentSize(contentSize)
    self.minSize = contentSize
    self.maxSize = contentSize
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
