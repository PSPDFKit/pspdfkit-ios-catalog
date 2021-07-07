//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomOutlineControllerExample: Example {

    override init() {
        super.init()

        title = "Custom Outline Controller"
        contentDescription = "Shows how to use a custom outline controller in the document info."
        category = .viewCustomization
        priority = 100
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        return PDFViewController(document: AssetLoader.document(for: .quickStart)) {
            $0.overrideClass(DocumentInfoCoordinator.self, with: CustomDocumentInfoCoordinator.self)
        }
    }
}

private class CustomDocumentInfoCoordinator: DocumentInfoCoordinator {

    override func controller(forOption option: DocumentInfoOption) -> UIViewController? {
        if option == .outline {
            return CustomOutlineViewController()
        } else {
            return super.controller(forOption: option)
        }
    }
}

private class CustomOutlineViewController: UIViewController, SegmentImageProviding {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemYellow

        let customLabel = UILabel()
        customLabel.translatesAutoresizingMaskIntoConstraints = false
        customLabel.text = "I am a custom outline controller"
        customLabel.textAlignment = .center
        view.addSubview(customLabel)

        NSLayoutConstraint.activate([
            customLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            customLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            customLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - PSPDFSegmentImageProviding

    var segmentImage: UIImage? {
        return SDK.imageNamed("x")
    }
}
