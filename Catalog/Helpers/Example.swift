//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit

// swiftlint:disable cyclomatic_complexity

extension Example {
    class func headerForExampleCategory(_ category: Example.Category) -> String {
        switch category {
        case .top:
            return "Basics"
        case .collaboration:
            return "Collaboration"
        case .swiftUI:
            return "SwiftUI"
        case .multimedia:
            return "Multimedia"
        case .annotations:
            return "Annotations"
        case .annotationProviders:
            return "Annotation Providers"
        case .forms:
            return "Forms and Digital Signatures"
        case .barButtons:
            return "Toolbar Customizations"
        case .viewCustomization:
            return "View Customizations"
        case .controllerCustomization:
            return "PDFViewController Customization"
        case .miscellaneous:
            return "Miscellaneous Examples"
        case .textExtraction:
            return "Text Extraction / PDF Creation"
        case .documentEditing:
            return "Document Editing"
        case .documentProcessing:
            return "Document Processing"
        case .documentGeneration:
            return "Document Generation"
        case .storyboards:
            return "Storyboards"
        case .documentDataProvider:
            return "Document Data Providers"
        case .security:
            return "Passwords / Security"
        case .subclassing:
            return "Subclassing"
        case .sharing:
            return "Document Sharing"
        case .componentsExamples:
            return "Components"
        case .analyticsClient:
            return "Analytics Client"
        case .tests:
            return "Miscellaneous Test Cases"
        case .industryExamples:
            return ""
        @unknown default:
            return ""
        }
    }

    class func footerForExampleCategory(_ category: Example.Category) -> String {
        switch category {
        case .top:
            return "Taking your first steps with PSPDFKit."
        case .collaboration:
            return "Examples showing how PSPDFKit Instant can be used for collaboration."
        case .swiftUI:
            return "Examples illustrating how PSPDFKit can be used in SwiftUI projects."
        case .multimedia:
            return "Integrate videos, audio, images and HTML5 content/websites as part of a document page."
        case .annotations:
            return "Add, edit or customize different annotations and annotation types."
        case .annotationProviders:
            return "Examples with different annotation providers."
        case .forms:
            return "Interact with or fill forms."
        case .barButtons:
            return "Customize the (annotation) toolbar."
        case .viewCustomization:
            return "Various ways to customize the view."
        case .controllerCustomization:
            return "Multiple ways to customize PDFViewController."
        case .miscellaneous:
            return "Examples showing how to customize PSPDFKit for various use cases."
        case .textExtraction:
            return "Extract text from document pages and create new document."
        case .documentEditing:
            return "New page creation, page duplication, reordering, rotation, deletion and exporting."
        case .documentProcessing:
            return "Various use cases for PSPDFProcessor, like annotation processing and page modifications."
        case .documentGeneration:
            return "Generate PDF Documents."
        case .storyboards:
            return "Initialize a PDFViewController using storyboards."
        case .documentDataProvider:
            return "Merge multiple file sources to one logical one using the highly flexible PSPDFDocument."
        case .security:
            return "Enable encryption and open password protected documents."
        case .subclassing:
            return "Various ways to subclass PSPDFKit."
        case .sharing:
            return "Examples showing how to customize the sharing experience."
        case .componentsExamples:
            return "Examples showing the various PSPDFKit components."
        case .analyticsClient:
            return "Examples using PDFAnalyticsClient."
        case .industryExamples:
            return ""
        case .tests:
            return ""
        @unknown default:
            return ""
        }
    }

    class func systemImageForExampleCategory(_ category: Example.Category) -> String {
        switch category {
        case .top:
            return "doc.text"
        case .collaboration:
            return "person.2.square.stack"
        case .swiftUI:
            return "swift"
        case .multimedia:
            return "tv.music.note"
        case .annotations:
            return "pencil.tip.crop.circle"
        case .annotationProviders:
            return "scribble"
        case .forms:
            return "doc.text"
        case .barButtons:
            return "capsule.fill"
        case .viewCustomization:
            return "gearshape"
        case .controllerCustomization:
            return "gearshape.2"
        case .miscellaneous:
            return "book.circle"
        case .textExtraction:
            return "text.redaction"
        case .documentEditing:
            return "doc.badge.gearshape"
        case .documentProcessing:
            return "doc.circle"
        case .documentGeneration:
            return "doc.fill.badge.plus"
        case .storyboards:
            return "checkerboard.rectangle"
        case .documentDataProvider:
            return "antenna.radiowaves.left.and.right"
        case .security:
            return "lock.circle"
        case .subclassing:
            return "line.3.crossed.swirl.circle"
        case .sharing:
            return "square.and.arrow.up.fill"
        case .componentsExamples:
            return "command.circle.fill"
        case .analyticsClient:
            return "person.2.circle"
        case .tests:
            return "note"
        case .industryExamples:
            return ""
        @unknown default:
            return ""
        }
    }

}

// swiftlint:enable cyclomatic_complexity

extension Example: Comparable {
    public static func < (example1: Example, example2: Example) -> Bool {
        if example1.category.rawValue < example2.category.rawValue {
            return true
        } else if example1.category.rawValue > example2.category.rawValue {
            return false
        } else if example1.priority < example2.priority {
            return true
        } else if example1.priority > example2.priority {
            return false
        } else {
            return example1.title.compare(example2.title) != .orderedDescending
        }
    }
}
