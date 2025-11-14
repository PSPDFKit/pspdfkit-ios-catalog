//
//  Copyright © 2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class ImportAnnotationsFromXFDFExample: Example {

    override init() {
        super.init()

        title = "Import annotations from XFDF"
        contentDescription = "Parses annotations from an XFDF file and adds them to a document."
        category = .annotations
        priority = 904
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .annualReport, overrideIfExists: true)

        // Use FileDataProvider if you’re loading XFDF from a file on disk. Here we show in-memory XFDF data.
        let xfdfDataProvider = DataContainerProvider(data: """
        <?xml version="1.0" encoding="UTF-8"?>
        <xfdf xml:space="preserve" xmlns="http://ns.adobe.com/xfdf/">
            <annots>
                <highlight color="#FEE832" coords="29.346500,791.247131,249.746521,791.247131,29.346500,762.297119,249.746521,762.297119" creationdate="D:20250408154538Z" date="D:20250408154538Z" flags="print" name="8AE5A7B2-8E80-46FC-9225-95265C2FD95C" page="0" pspdf-blend-mode="multiply" rect="18.326500,760.849609,260.766510,792.694641" title="Nutrient" width="0.000000"/>
                <text color="#E75541" creationdate="D:20250408154547Z" date="D:20250408154746Z" flags="print" icon="Star" name="275AFB80-EC2C-4238-8E63-6C7F7B4A71D0" page="0" rect="498.541107,465.364990,530.541077,497.364990" title="Nutrient" width="0.000000">
                    <contents>This is a note from XFDF.</contents>
                    <contents-richtext>
                        <body xmlns="http://www.w3.org/1999/xhtml" xmlns:xfa="http://www.xfa.org/schema/xfa-data/1.0/" xfa:APIVersion="Acrobat:11.0.12" xfa:spec="2.0.2">
                            <p>
                                <span style="color: #E75541">This is a note from XFDF.</span>
                            </p>
                        </body>
                    </contents-richtext>
                </text>
                <freetext creationdate="D:20250408154559Z" date="D:20250408154632Z" flags="print" fringe="0.000000,0.000000,0.000000,0.000000" name="84A299E8-1BDD-43F0-A4E7-C84BDC652D77" page="0" pspdf-text-should-fit="true" rect="38.250000,641.491028,338.490356,673.491028" title="Nutrient" width="0.000000">
                    <contents>Text annotation from XFDF</contents>
                    <contents-richtext>
                        <body xmlns="http://www.w3.org/1999/xhtml" xmlns:xfa="http://www.xfa.org/schema/xfa-data/1.0/" xfa:APIVersion="Acrobat:11.0.12" xfa:spec="2.0.2">
                            <p>
                                <span style="color: #2492FB">Text annotation from XFDF</span>
                            </p>
                        </body>
                    </contents-richtext>
                    <defaultappearance>/Helvetica 24.959 Tf 0.141176 0.572549 0.984314 rg </defaultappearance>
                    <defaultstyle>font:24.96pt &quot;Helvetica&quot;; color:#2492FB; </defaultstyle>
                </freetext>
                <square color="#3FB43D" creationdate="D:20250408154718Z" date="D:20250408154735Z" flags="print" name="B04A32A6-A785-4DCC-AC85-7237990592EE" page="0" rect="53.969177,384.777039,364.684937,552.756104" style="solid" title="Nutrient" width="5.000000"/>
            </annots>
        </xfdf>

        """.data(using: .utf8)!)

        let parser = XFDFParser(dataProvider: xfdfDataProvider, documentProvider: document.documentProviders[0])

        do {
            let annotations = try parser.parse()
            document.add(annotations: annotations)
        } catch {
            let alert = UIAlertController(title: "Couldn’t Read XFDF", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            delegate.currentViewController!.present(alert, animated: true)
            return nil
        }

        return PDFViewController(document: document)
    }
}
