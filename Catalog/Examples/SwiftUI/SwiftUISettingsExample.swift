//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import SwiftUI
import PSPDFKitUI
import Combine

class SwiftUISettingsExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Settings Example"
        contentDescription = "Shows how to show a PDFViewController in SwiftUI with Settings."
        category = .swiftUI
        priority = 11
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        let swiftUIView = SwiftUISettingsExampleView(store: SwiftUISettingsExampleViewModel(document: document))
        return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
    }
}

class SwiftUISettingsExampleViewModel: ObservableObject {
    @Published var document: Document

    init(document: Document) {
        self.document = document
    }
}

private struct SwiftUISettingsExampleView: View {
    @ObservedObject var store: SwiftUISettingsExampleViewModel
    @State private var scrollDirection = ScrollDirection.horizontal
    @State private var pageTransition = PageTransition.scrollPerSpread
    @State private var pageIndex = PageIndex(0)

    var body: some View {
        return VStack(alignment: .center) {

            Text("SwiftUI Settings Example")
                .font(.largeTitle)
                .padding(.top, 100)

            // UIStepper is not allowed for Catalyst Mac Idiom.
            if !UIDevice.current.isCatalystMacIdiom {
                Stepper("Current Page: \(pageIndex + 1)", value: $pageIndex, in: 0...store.document.pageCount - 1)
                .padding()
            }

            SettingsView(scrollDirection: $scrollDirection, pageTransition: $pageTransition)
                .padding()

            Button("Toggle Document") {
                if store.document.title == "Magazine" {
                    store.document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
                } else {
                    store.document = AssetLoader.writableDocument(for: .magazine, overrideIfExists: false)
                }
            }

            PDFView(document: store.document, pageIndex: $pageIndex)
                .useParentNavigationBar(true)
                .scrollDirection(scrollDirection)
                .pageTransition(pageTransition)
                .pageMode(.single)
                .userInterfaceViewMode(.always)
                .spreadFitting(.fill)
        }

        // Prevent jumping of the content as we show/hide the navigation bar
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: Settings Logic

extension ScrollDirection: CaseIterable {
    public static var allCases: [Self] {
        [.horizontal, .vertical]
    }
}

extension ScrollDirection: Localizable {
    var localizedName: LocalizedStringKey {
        switch self {
        case .horizontal: return "Horizontal"
        case .vertical: return "Vertical"
        }
    }
}

extension PageTransition: CaseIterable {
    public static var allCases: [Self] {
        [.scrollPerSpread, .scrollContinuous, .curl]
    }
}

extension PageTransition: Localizable {
    var localizedName: LocalizedStringKey {
        switch self {
        case .scrollPerSpread: return "Scroll per Spread"
        case .scrollContinuous: return "Scroll Continuous"
        case .curl: return "Page Curl"
        }
    }
}

struct NamedPicker<EnumType>: View where EnumType: Hashable & Equatable & Localizable,
                                         EnumType.AllCases: RandomAccessCollection {
    let title: String
    @Binding var value: EnumType
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        VStack {
            Text(title)
            Picker(selection: $value, label: Text(title)) {
                ForEach(EnumType.allCases, id: \EnumType.self) { value in
                    Text(value.localizedName).tag(value)
                }
            }.pickerStyle(SegmentedPickerStyle())
        }
    }
}

struct SettingsView: View {
    @Binding var scrollDirection: ScrollDirection
    @Binding var pageTransition: PageTransition

    var body: some View {
        AdaptiveStack {
            NamedPicker(title: "Scroll Direction", value: $scrollDirection)
            NamedPicker(title: "Page Transition", value: $pageTransition)
        }
    }
}

// MARK: Previews

struct SwiftUISettinsExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(for: .quickStart)
        SwiftUISettingsExampleView(store: SwiftUISettingsExampleViewModel(document: document))
    }
}
