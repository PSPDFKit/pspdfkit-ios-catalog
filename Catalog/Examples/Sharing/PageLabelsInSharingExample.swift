//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class PageLabelsInSharingExample: Example {

    override init() {
        super.init()

        title = "Show Page Labels in the Sharing UI"
        contentDescription = "Shows how to display page labels instead of page numbers in the sharing UI."
        category = .sharing
        priority = 900
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)

        let pdfViewController = PDFViewController(document: document) { mainConfiguration in
            mainConfiguration.sharingConfigurations = mainConfiguration.sharingConfigurations.map { sharingConfiguration in
                sharingConfiguration.configurationUpdated { sharingConfigurationBuilder in

                    /*
                     By default PSPDFKit displays page numbers in the sharing UI for picking a page range and
                     showing the selected pages. This ensures the UI is easy to understand for any document.
                     You can use `pageDescriptionProvider` and `selectedPagesDescriptionProvider` to customize
                     these strings. This example shows how to display the page labels set in the PDF instead.
                     */

                    sharingConfigurationBuilder.pageDescriptionProvider = { pageIndex, document in
                        document.pageLabelForPage(at: pageIndex, substituteWithPlainLabel: true)!
                    }

                    let originalSelectedPagesDescriptionProvider = sharingConfigurationBuilder.selectedPagesDescriptionProvider

                    sharingConfigurationBuilder.selectedPagesDescriptionProvider = { selectedPages in
                        switch selectedPages {
                        case .all, .annotated:
                            // Use the default PSPDFKit implementation.
                            return originalSelectedPagesDescriptionProvider(selectedPages)
                        case .current(let currentPageIndex, let document):
                            // Show the page label instead of the page number.
                            // Not shown here, but you should localize this string using NSLocalizedString.
                            return String.localizedStringWithFormat("Current Page (%@)", document.pageLabelForPage(at: currentPageIndex, substituteWithPlainLabel: true)!)
                        case .range(let selectedPageIndexes, let document):
                            // Show the page labels instead of the page numbers.
                            // Not shown here, but you should localize this string using NSLocalizedString.
                            // This only shows supporting a single range in the index set. In practice,
                            // the PSPDFKit UI only allows setting a single range for now so this is fine.
                            return String.localizedStringWithFormat(
                                "Pages %@–%@",
                                document.pageLabelForPage(at: PageIndex(selectedPageIndexes.first!), substituteWithPlainLabel: true)!,
                                document.pageLabelForPage(at: PageIndex(selectedPageIndexes.last!), substituteWithPlainLabel: true)!
                            )
                        }
                    }
                }
            }
        }

        return pdfViewController
    }
}
