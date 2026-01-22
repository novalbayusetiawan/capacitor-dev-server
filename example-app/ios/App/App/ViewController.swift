import UIKit
import Capacitor
import CapacitorDevServer

class ViewController: CAPBridgeViewController {

    override func capacitorOptions() -> [String : Any]! {
        var options = super.capacitorOptions() ?? [:]
        
        // Merge with our dev server options
        let devOptions = CapacitorDevServer.capacitorOptions()
        for (key, value) in devOptions {
            options[key] = value
        }
        
        return options
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

}
