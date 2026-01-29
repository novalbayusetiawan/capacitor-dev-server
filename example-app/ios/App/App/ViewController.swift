import UIKit
import Capacitor
import CapacitorDevServer

class ViewController: CAPBridgeViewController {

    override func instanceDescriptor() -> InstanceDescriptor {
        let descriptor = super.instanceDescriptor()
        
        // Merge with our dev server options
        let devOptions = DevServer.capacitorOptions()
        if let server = devOptions["server"] as? [String: Any],
           let url = server["url"] as? String {
            descriptor.serverURL = url
        }
        
        return descriptor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

}
