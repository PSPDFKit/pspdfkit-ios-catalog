//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import MapKit

class MapWidgetExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Page with Apple Maps Widget"
        category = .viewCustomization
        priority = 50
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .JKHF)
        document.annotationSaveMode = .disabled

        // This annotation could be already in the document - we just add it programmatically for this example.
        let linkAnnotation = LinkAnnotation(url: URL(string: "map://37.7998377,-122.400478,0.005,0.005")!)
        linkAnnotation.linkType = .browser
        linkAnnotation.boundingBox = CGRect(x: 100, y: 100, width: 300, height: 300)
        linkAnnotation.pageIndex = 0
        document.add(annotations: [linkAnnotation])

        let pdfController = PDFViewController(document: document, delegate: self) {
            $0.thumbnailBarMode = .none
        }
        return pdfController
    }

    // MARK: PDFViewControllerDelegate

    internal func pdfViewController(_ pdfController: PDFViewController, annotationView: (UIView & AnnotationPresenting)?, for annotation: Annotation, on pageView: PDFPageView) -> (UIView & AnnotationPresenting)? {
        if let linkAnnotation = annotation as? LinkAnnotation {
            // example how to add a MapView with the url protocol map://lat,long,latspan,longspan
            if linkAnnotation.linkType == .browser, let urlString = linkAnnotation.url?.absoluteString, urlString.hasPrefix("map://") {

                // parse annotation data
                let mapString = urlString.replacingOccurrences(of: "map://", with: "")
                let mapTokens = mapString.components(separatedBy: ",")

                // ensure we have mapTokens count of 4 (latitude, longitude, span la, span lo)
                if mapTokens.count == 4,
                    let latitude = Double(mapTokens[0]),
                    let longitude = Double(mapTokens[1]),
                    let latspan = Double(mapTokens[2]),
                    let longspan = Double(mapTokens[3]) {

                    let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                    let span = MKCoordinateSpan(latitudeDelta: latspan, longitudeDelta: longspan)

                    // frame is set in PDFViewController, but MKMapView needs the position before setting the region.
                    let frame = annotation.boundingBox(forPageRect: pageView.bounds)

                    let mapView = MapView(frame: frame)
                    mapView.setRegion(MKCoordinateRegion(center: location, span: span), animated: false)
                    return mapView
                }
            }
        }
        return annotationView
    }
}

// This class is needed since we can't simply add a protocol to an object in Swift, so we need to use a subclass for our mapView here
private class MapView: MKMapView, AnnotationPresenting {}
