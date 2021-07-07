//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import UIKit

class Application: UIApplication {
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)

        /// Detect Apple Pencil availability.
        ///
        /// There is no simple way to know whether a device supports Apple Pencil.
        /// All an app knows is that if it receives a touch event of type `pencil` then an Apple Pencil was connected at that time.
        /// For more details check: https://pspdfkit.com/guides/ios/annotations/apple-pencil/#apple-pencil-availability
        let applePencilManager = SDK.shared.applePencilManager

        if applePencilManager.detected || event.type != .touches {
            return
        }

        guard let touches = event.allTouches, !touches.isEmpty else {
            return
        }

        for touch in touches {
            if touch.type == .pencil && touch.phase == .began {
                applePencilManager.detected = true
            }
        }
    }
}
