//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class DynamicMarginsExample: Example {

    override init() {
        super.init()
        title = "Margin Customization Example"
        contentDescription = "Shows how adjust the content for your custom user interface elements."
        category = .controllerCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .quickStart)
        let pdfController = CustomUserInterfaceController(document: document) {
            $0.pageTransition = .curl
            $0.userInterfaceViewMode = .always
            $0.thumbnailBarMode = .none
        }
        return pdfController
    }

    // MARK: - View controller

    class CustomUserInterfaceController: PDFViewController {

        override func viewDidLoad() {
            super.viewDidLoad()
            setUpBottomBar()
        }

        // MARK: Bottom bar

        let bottomBar = CustomBottomBar()

        private func setUpBottomBar() {
            bottomBar.toggleButton.addTarget(self, action: #selector(togglePressed), for: .touchUpInside)
            bottomBar.translatesAutoresizingMaskIntoConstraints = false
            userInterfaceView.addSubview(bottomBar)

            let views = ["bottomBar": bottomBar]
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[bottomBar]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
            NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[bottomBar]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))

            updateCongigurationForBottomBar()
        }

        @objc private func togglePressed() {
            bottomBar.expanded = !bottomBar.expanded
            updateCongigurationForBottomBar()
        }

        private func updateCongigurationForBottomBar() {
            let bottomBarInset = bottomBar.intrinsicContentSize.height
            // Note changing the margin requires updateConfigurationWithBuilder (a reload).
            updateConfiguration {
                $0.additionalScrollViewFrameInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomBarInset, right: 0)
            }
            // Lets also move the page label above the bottom bar.
            userInterfaceView.pageLabelInsets = UIEdgeInsets(top: 0, left: 5, bottom: 10 + bottomBarInset, right: 5)
        }
    }

    // MARK: - User Interface view

    class CustomBottomBar: UIView {

        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpViews()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setUpViews()
        }

        private func setUpViews() {
            backgroundColor = UIColor.catalogTint.withAlphaComponent(0.7)

            toggleButton.setTitle("Expand / Collapse", for: UIControl.State())
            toggleButton.translatesAutoresizingMaskIntoConstraints = false
            addSubview(toggleButton)

            NSLayoutConstraint(item: toggleButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: toggleButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        }

        // MARK: State

        let toggleButton = UIButton(type: .custom)

        var expanded = false {
            didSet {
                invalidateIntrinsicContentSize()
            }
        }

        // MARK: Layout

        override var intrinsicContentSize: CGSize {
            return CGSize(width: UIView.noIntrinsicMetric, height: expanded ? 44 * 3 : 44)
        }
    }
}
