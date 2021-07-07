//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// Extending the type with custom events.
extension PDFAnalytics.EventName {
    static var catalogAnalyticsExampleOpen = PDFAnalytics.EventName(rawValue: "catalog_analytics_example_open")
    static var catalogAnalyticsExampleExit = PDFAnalytics.EventName(rawValue: "catalog_analytics_example_exit")
}

class AnalyticsClientExample: Example, PDFViewControllerDelegate {

    class CustomAnalyticsClient: PDFAnalyticsClient {
        func logEvent(_ event: PDFAnalytics.EventName, attributes: [String: Any]?) {
            print("\(event) \(String(describing: attributes))")
        }
    }

    let analyticsClient = CustomAnalyticsClient()

    override init() {
        super.init()

        title = "Analytics Client"
        contentDescription = "Example implementation of PDFAnalyticsClient that logs events to console."
        category = .analyticsClient
        priority = .max // this places the example at the bottom of the list, obviously ;)
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)

        let analytics = SDK.shared.analytics

        analytics.add(analyticsClient)
        analytics.enabled = true

        let controller = PDFViewController(document: document)
        controller.delegate = self

        // sending custom events
        analytics.logEvent(.catalogAnalyticsExampleOpen)

        return controller
    }

    func pdfViewControllerDidDismiss(_ pdfController: PDFViewController) {
        let analytics = SDK.shared.analytics

        // sending custom events
        analytics.logEvent(.catalogAnalyticsExampleExit)

        analytics.remove(analyticsClient)
        analytics.enabled = false
    }
}
